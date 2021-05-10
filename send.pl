#!/usr/bin/perl
use File::Path;
use DBI;
use DBD::SQLite;
use Net::SMTP;


#exit;


$basedir=shift;
$hash=shift;
$id=shift;
$fname=shift;

open(FF,'/tmp/trans.log');

print FF "$basedir\n";
print FF "$hash\n";
print FF "$id\n";
print FF "$fname\n";

close(FF);

$mail_user_to='mt@vbbs.tech';
$mail_user_from='torrent@vbbs.tech';
$mail_server='10.10.0.10';

print "id:$id fname:$fname\n";

$busy='/opt/down-scripts/chkspace.flag';
$mntflag='/mnt/down/down-mounted';
$datadir='/opt/down-scripts/data';
$copydir='/data/down';

$db='/opt/down-scripts/queue.db';


$fn="$basedir/$fname";
$log="/tmp/deluge-log-$id";

print "FileName:[$fn]\n";

if ( -d $fn ) # эт каталог
    {
     $type='D';
     $sz=`du -bs '$fn'`;
     @s=split("[(\ )|(\t)]+",$sz);
     $size=$s[0];
    } # каталог
    else
    {
      $type='T';
      $size = (stat $fn)[7];
    }

    open(F,">$log");

    
    $dbh = DBI->connect("dbi:SQLite:dbname=$db","","",{RaiseError => 1, AutoCommit => 1});

    $sth = $dbh->prepare('INSERT INTO queue (tid,hash,filename,size) VALUES(?,?,?,?)');
    $sth->execute($id,$hash,$fname,$size);
    
    $sth->finish;
    
    $sth = $dbh->prepare('select max (id) from queue');
    $sth->execute();
    
    @row=$sth->fetchrow_array();
    $id=@row[0];
    print F "id:$id\n";
    
    $sth->finish;
    $dbh->disconnect();
    
    $cdir="$copydir/$id";
    mkdir($cdir);
    print F "cdir:$cdir\n";
    
    $cmd="ssh data\@10.10.0.10 'mkdir $cdir'";
    print F "cmd:$cmd\n";
    print "cmd:$cmd\n";
    system($cmd);
    
    $fn=`/opt/down-scripts/q.sh "$fn"`;
    chomp($fn);

    
    $cmd="scp -rv $fn data\@10.10.0.10:$cdir";
    print F "cmd:$cmd\n";
    print "cmd:$cmd\n";
    system($cmd);
    

    $cmd="ssh data\@10.10.0.10 'chmod -R a+rwx $cdir'";
    print F "cmd:$cmd\n";
    print "cmd:$cmd\n";
    system($cmd);

    
    
    $dbh = DBI->connect("dbi:SQLite:dbname=$db","","",{RaiseError => 1, AutoCommit => 1});
    $sth = $dbh->prepare('update queue set zipped=1 where id=?');
    $sth->execute($id);
    $sth->finish;
    $dbh->disconnect();
    
close(F);

open(F,$log);
$s='';
while ($l=<F>)
{
$s="$s$l";
}
close(F);


    $subj="torrent [$fname] downloaded";
    $body=$s;
    
    sendMail($subj,$body);


system("rm '$log'");

exit;

#$auth='127.0.0.1:5577 --auth mt:Master24!';

#$porog=70;


#my $host = "localhost"; # MySQL-сервер нашего хостинга
#my $port = "3306"; # порт, на который открываем соединение
#my $user = "root"; # имя пользователя
#my $pass = "ukffkm"; # пароль
#my $db = "down"; # имя базы данных

#$connection = DBI->connect("DBI:mysql:$db:$host:$port", $user,$pass);

#$connection = DBI->connect("DBI:mysql:$db:$host:$port", $user,$pass);


$sp=getPr();
#print "$sp\n";

if ($sp>$porog)
    {

    $connection = DBI->connect("dbi:SQLite:dbname=$db","","",{RaiseError => 1, AutoCommit => 1});
    $q="select * from queue where zipped=1 and deleted=1 order by id";
    $statement = $connection->prepare($q);
    $statement->execute();


    while ($sp>$porog)
    {
     print "$sp > $porog\n";
     
     @row = $statement->fetchrow_array();
     $id=$row[0];
     $tid=$row[1];
     $fn=$row[3];
     $hash=$row[2];

     if ($id eq '') { last; }
    
#    ($id,$hash,$fn)=split('\|',$ln,3);
    print "($id,$hash,$fn)\n";
    
    $cmd="/volume1/\@appstore/transmission/bin/transmission-remote $auth -t $hash --remove-and-delete";
    print "$cmd\n";
    system($cmd);
    
    if (-d "$fn")
     {
     rmtree($f,1);
     print "rmtree($f,1)\n";
     } else
     { 
     
     if (-e "$fn")    		{ 
    		 unlink($fn);
    		 print "unlink($fn);\n";
                 }
     }
    
    $q1="delete from queue where id=$id";
    $st = $connection->prepare($q1);
    $st->execute();

    $sp=getPr();
    }
    print "Usage: [$sp] <= [$porog]\n";

}


system("rm $busy");


exit;


sub getPr()
{
    my $c=`df -h | grep "\/data\$"`;
    chomp($c);
#    print ($c);
    $c=~s/[ ]+/ /gi;
    my @sp=split(' ',$c);
    my $pr=$sp[4];
    $pr=~s/\%//;
    return $pr;
}


sub sendMail()
{

$subj=shift;
$Body=shift;

$smtp = Net::SMTP->new($mail_server,Hello => 'yama',
                           Timeout => 30,
                           Debug   => 1,);
$smtp->auth ("deluge","ltk.uf");

 $smtp->mail($mail_user_from);
    if ($smtp->to($mail_user_to)) {
     $smtp->data();
     $smtp->datasend("To: $mail_user_to\n");
     $smtp->datasend("Subject: $subj\n");
     $smtp->datasend("\n");
     $smtp->datasend($Body);
     $smtp->dataend();
    } else {
     print "Error: ", $smtp->message();
    }
}
