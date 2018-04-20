$version = git log -1 --pretty=format:%cd --date=format:%y%m%d
echo "AI-Trans version $version"
$invocation = (Get-Variable MyInvocation).Value
$directorypath = Split-Path $invocation.MyCommand.Path
$folder = $directorypath + '\Trans-AI_' + $version
echo "Archive & extraction"
git archive --format=tar --output=temp.tar master
mkdir $folder
tar -xf temp.tar -C $folder
echo "Version correction"
$infonut = $folder + '\info.nut'
$content = [System.IO.File]::ReadAllText($infonut).Replace("return 200101","return $version")
[System.IO.File]::WriteAllText($infonut, $content)
echo "creating bundle"
tar -cf Trans-AI_$version.tar -C $directorypath Trans-AI_$version
del temp.tar
del -recurse Trans-AI_$version 
#$mydoc = ([environment]::getfolderpath("mydocuments"))+'\openttd\ai'
#is install
#ls $mydoc
