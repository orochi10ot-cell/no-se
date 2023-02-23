<# 
Disabling Edge from Opening when Internet Explorer tries to Open
by hihi217
February 22, 2023

This script renames the files related to Microsoft Edge's Internet Explorer Browser Helper Object (BHO)
used to open Edge when Internet Explorer tries to open.
This lets a user run legacy websites in Internet Explorer that may not work in IE Mode on Edge.
This is provided as-is as Microsoft may break this workaround, and the script may cause issues with your device.
#>

# UAC Elevation: https://superuser.com/a/532109
param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

""
"Disabling Edge from Opening when Internet Explorer tries to Open"
"by hihi217"
""
"THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
""
"This script will rename any files related to Microsoft Edge's Internet Explorer Browser Helper Object (BHO), disabling Internet Explorer
redirects to Edge, allowing a user to use Internet Explorer for certain websites."
""
Read-Host -Prompt "Press enter key to continue, and to agree to the above or CTRL+C to quit"
""

# Checks to see where the "Edge" folder exists on the system, either in the "Program Files" folder,
# or the "Program Files (x86)" folder, then sets "EdgeFolder" to the parent directory.

$x64Folder = ${Env:ProgramFiles(x86)} + '\Microsoft\Edge'
$x86Folder = ${Env:ProgramFiles} + '\Microsoft\Edge'
$EdgeFolder = "null"

if (Test-Path -Path $x86Folder) 
{
    #"x86 Path does exist."
    $EdgeFolder = ${Env:ProgramFiles} + '\Microsoft\'

} 
    elseif (Test-Path -Path $x64Folder)
    {
        #"x64 Path does exist."
        $EdgeFolder = ${Env:ProgramFiles(x86)} + '\Microsoft\'
    }
        else
        {
            "Error selecting path. Please contact the developer."
            pause
            exit
        }


#"$EdgeFolder" # writes folder path to console

if ($EdgeFolder -eq "null")
{
    exit
}

# Gets all files named "ie_to_edge", going through all folders in %ProgramFiles%\Microsoft\ or
# %ProgramFiles(x86)\Microsoft\ on 64-bit operating systems.

$FilestoRename = dir -Path $EdgeFolder -Filter ie_to_edge* -Recurse 


# Checks to see if files have been renamed already, if so, exit the script, if not, continues to
# rename all files.

$filenameextensions = $FilestoRename | %{$_.name.substring($_.name.length -3)}
$matchpattern = "bak"
$matchingValues = $filenameextensions | Where { "$filenameextensions.GetValue($_)" -match $matchPattern }

if($filenameextensions.Count -eq $matchingValues.Count)
{
    "It looks like you have run this before, exiting."
    #$FilestoRename | Rename-Item -newname {$_.name.substring(0,$_.name.length-4)} # removes .bak extension 
    pause
    exit
}
    else
    {
        #$FilestoRename | %{$_.FullName}                                               # outputs old file names
        "Renaming all files."
        $FilestoRename | Rename-Item -newname {($PSItem.Name +".bak")}
    
        #$FilestoRename = dir -Path $EdgeFolder -Filter ie_to_edge* -Recurse           # gets new filenames
        #$FilestoRename | %{$_.FullName}                                               # outputs new file names
        "Renamed all files, exiting."
        pause
        exit
    }