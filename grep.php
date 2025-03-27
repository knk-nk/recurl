<form action="<?=$PHP_SELF;?>" method="POST" style="font-family: Verdana">
	<br><input type="text" name="grep" placeholder="Code text search" pattern="[^&;\n\\]+"><br>
	<input type="text" name="ext" placeholder="File extension" value=".php" pattern="[a-zA-Z0-9.]+"><br><br>
	<input type="text" name="find" placeholder="Filename search" pattern="[a-zA-Z0-9 ._\-]+"><br><br>
	<input type="submit" value="Find">
</form><hr>

<?
if (!empty($_POST)) {
$str_grep=preg_filter('/[&;\n\\\]*/', '', $_POST["grep"]);
$str_find=preg_filter('/[^a-zA-Z0-9 _\-.]*/', '', $_POST["find"]);
$ext=preg_filter('/[^a-zA-Z0-9.]*/', '', $_POST["ext"]);

echo '<pre>';
if ($str_grep && ($str_grep != "")) {
	$grep=shell_exec("grep -rn --include=\*$ext '$str_grep' .");
	echo 'Code found:<br><br>';
	print_r(str_replace(array("<", ">"), array("&lt;", "&gt;"), $grep));
	echo '<br><hr><br>';
}
if ($str_find && ($str_find != "")) {
	$find=shell_exec("find . -name $str_find");
	echo 'Files found:<br><br>';
	print_r(str_replace(array("<", ">"), array("&lt;", "&gt;"), $find));
}
echo '</pre>';
}
?>
