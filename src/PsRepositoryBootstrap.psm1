

$functionFolders = @('enum','class','public','private' )
ForEach ($folder in $functionFolders)
{
    $folderPath = Join-Path -Path $PSScriptRoot -ChildPath $folder
    If (Test-Path -Path $folderPath)
    {
        Write-Verbose -Message "Importing from $folder"
        $FunctionFiles = Get-ChildItem -Path $folderPath -Filter '*.ps1' -Recurse | Where-Object { $_.Name -notmatch '\.tests{0,1}\.ps1' }
        ForEach ($FunctionFile in $FunctionFiles)
        {
            Write-Debug -Message "  Importing $($FunctionFile.BaseName)"
            . $($FunctionFile.FullName)
        }
    }    
}
$folderPath = Join-Path -Path $PSScriptRoot -ChildPath 'public'
$FunctionFiles = Get-ChildItem $folderPath -Filter '*.ps1' -Recurse | Where-Object { $_.Name -notmatch '\.tests{0,1}\.ps1' }
foreach ($FunctionFile in $FunctionFiles) {
    $AST = [System.Management.Automation.Language.Parser]::ParseFile($FunctionFile.FullName, [ref]$null, [ref]$null)        
    $Functions = $AST.FindAll({
            $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)
    if ($Functions.Name) {
        Export-ModuleMember -Function $Functions.Name
    }
}
