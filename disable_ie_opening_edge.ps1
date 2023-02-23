<# 
Disabling Edge from Opening when Internet Explorer tries to Open
by hihi217
February 22, 2023

This script renames the files related to Microsoft Edge's Internet Explorer Browser Helper Object (BHO)
used to open Edge when Internet Explorer tries to open.
This lets a user run legacy websites in Internet Explorer that may not work in IE Mode on Edge.

This also includes a way to add changes to the Group Policy that can disable the redirect add-on, 
however it has not been tested, and may or may not work.

This is provided as-is as Microsoft may break this workaround, and the script may cause issues with your device.

#>


<###################################################################################################################################### 

Powershell Execution Policy
By default you may not be able to run any powershell scripts unless you change Windows' execution policy. Try setting to "RemoteSigned".

See tutorial on changing execution policy here: https://www.tenforums.com/tutorials/54585-change-powershell-script-execution-policy-windows-10-a.html

From: https://github.com/ThioJoe/youtube-dl-easy#powershell-execution-policy

######################################################################################################################################>


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

# Creates a menu for the user to select the option they would like to use.

function menu()
{
    
    if ($EdgeFolder -eq $null)
    {
        exit
    }

    Write-Host ""
    Write-Host "What would you like to do?" 

    Write-Host "Press f to" -NoNewline
    Write-Host " disable " -NoNewLine -ForegroundColor Red
    Write-Host "the IEtoEdge BHO, turning off Edge redirection."

    Write-Host "Press o to" -NoNewline
    Write-Host " enable " -NoNewLine -ForegroundColor Green
    Write-Host "the IEtoEdge BHO, enabling Edge redirection."

    Write-Host "Press d to" -NoNewline
    Write-Host " delete " -NoNewLine -ForegroundColor Green
    Write-Host "the IEtoEdge BHO files (Note: Once files are deleted, " -NoNewline
    Write-Host "changes cannot be reverted." -NoNewline -ForegroundColor Red
    Write-Host ".)"

    Write-Host ""
    Write-Host "Group Policy edits have not been tested, may or may not work. Execute at your own risk." -ForegroundColor Magenta

    Write-Host "Press g to" -NoNewline
    Write-Host " enable " -NoNewLine -ForegroundColor Red
    Write-Host "Group Policies that should disable IEtoEdge BHO,"
    Write-Host "disabling " -NoNewLine -ForegroundColor Red
    Write-Host "Edge redirection."

    Write-Host "Press i to" -NoNewline
    Write-Host " enabling " -NoNewLine -ForegroundColor Green
    Write-Host "Group Policies that should disable IEtoEdge BHO,"
    Write-Host "enabling " -NoNewLine -ForegroundColor Green
    Write-Host "Edge redirection."

    Write-Host ""
    Write-Host "Press e to exit."

    switch ((Read-Host -Prompt "Enter here").Substring(0,1))
    {
        "f" 
        {
            ""
            disableBHO
            ""
        }
        "o"
        {
            ""
            enableBHO
            ""
        }
        "d"
        {
            ""
            deleteBHO
            ""
        }
        "g"
        {
            ""
            Write-Host "Would you like to enable Group Policies that disables IEtoEdgeBHO?"
            if(agree("Press y to continue, press any other key to exit") -eq $true)
            {
                updateGPO(1)
            }
            else
            {
                "Exiting to menu."
                menu
            }
            ""
        }
        "i"
        {
            ""
            Write-Host "Would you like to disable Group Policies that disables IEtoEdgeBHO?"
            if(agree("Press y to continue, press any other key to exit") -eq $true)
            {
                updateGPO(0)
            }
            else
            {
                "Exiting to menu."
                menu
            }
            ""
        }
        "e"
        {
            ""
            Write-Host "Exiting the program."
            exit
            $gotDirectory = "false"
            pause
        }
        default
        {
            Write-Host "Incorrect letter entered, returning to menu."
            menu
        }
   }

}

###################################################################################################################################### 


function getDirectory()
{
    # Checks to see where the "Edge" folder exists on the system, either in the "Program Files" folder,
    # or the "Program Files (x86)" folder, then sets "EdgeFolder" to the parent directory.
    ""
    $x64Folder = ${Env:ProgramFiles(x86)} + '\Microsoft\Edge'
    $x86Folder = ${Env:ProgramFiles} + '\Microsoft\Edge'
    $global:EdgeFolder = $null

    if (Test-Path -Path $x86Folder) 
    {
        $global:EdgeFolder = ${Env:ProgramFiles} + '\Microsoft\'
        Write-Host ("x86 Path does exist, continuing. (" + $EdgeFolder + ")")
        $gotDirectory = "true"

    } 
        elseif (Test-Path -Path $x64Folder)
        {
            $global:EdgeFolder = ${Env:ProgramFiles(x86)} + '\Microsoft\'
            Write-Host ("x64 Path does exist, continuing. (" + $EdgeFolder + ")")
            $gotDirectory = "true"
        }
            else
            {
                Write-Host "Error finding Microsoft Edge directory. Please contact the developer."
                pause
                exit
            }
}


# Gets all files starting with the name "ie_to_edge", going through all folders in %ProgramFiles%\Microsoft\ or
# %ProgramFiles(x86)%\Microsoft\ on 64-bit operating systems.

function findFiles()
{
    return dir -Path $EdgeFolder -Filter ie_to_edge* -Recurse 
}


function disableBHO()
{
    # Checks to see if files have been renamed already, if so, exit to menu, if not, continues to
    # rename all files.
    
    $FilestoRename = findfiles
    $filenameextensions = $FilestoRename | %{$_.name.substring($_.name.length -3)}
    $matchpattern = "bak"
    $matchingValues = $filenameextensions | Where { "$filenameextensions.GetValue($_)" -match $matchPattern }
    if($filenameextensions.Count -eq $matchingValues.Count -or $filenameextensions.Count -eq 0)
    {
        Write-Host "It looks like you have run this before or all files have been deleted, the script will not continue. `nGoing back to menu..."
        pause
        menu
    }
        else
        {
            Write-Host "This portion of the script will rename these files, adding the "".bak"" extension to the end of the file."
            $FilestoRename | %{$PSItem.Name + " -> " + ($PSItem.Name + ".bak")}                                              
            #$FilestoRename | %{($PSItem.Name + ".bak")}                                    # outputs old file names
            ""
            if (agree("Press y to continue renaming, press any other key to exit"))
            {
                Write-Host "Renaming files."
                $FilestoRename | Rename-Item -newname {($PSItem.Name +".bak")}
                Write-Host "Renamed all files, exiting to menu."
                pause
                menu
            }
            else
            {
                Write-Host "Exiting..."
                pause
                menu
            }
    
            #$FilestoRename = dir -Path $EdgeFolder -Filter ie_to_edge* -Recurse           # gets new filenames
            #$FilestoRename | %{$_.FullName}                                               # outputs new file names
            pause
            menu
        }
}

function enableBHO()
{
    # Checks to see if files have been renamed already, if so, exit to menu, if not, continues to
    # rename all files.
    
    $FilestoRename = findfiles
    $filenameextensions = $FilestoRename | %{$_.name.substring($_.name.length -3)}
    $matchpattern = "bak"
    $matchingValues = $filenameextensions | Where { "$filenameextensions.GetValue($_)" -match $matchPattern }
    if($filenameextensions.Count -ne $matchingValues.Count -or $FilestoRename.Count -eq 0)
    {
        Write-Host "It looks like you have run this before or all files have been deleted, the script will not continue. `nGoing back to menu..."
        pause
        menu
    }
        else
        {
            Write-Host "This portion of the script will rename these files, removing the "".bak"" extension at the end of the file."
            $FilestoRename | %{$PSItem.Name + " -> " + ($_.name.substring(0,$_.name.length-4))}                                              
            #$FilestoRename | %{($PSItem.Name + ".bak")}                                    # outputs old file names
            ""
            if (agree("Press y to continue renaming, press any other key to exit"))
            {
                Write-Host "Renaming files."
                $FilestoRename | Rename-Item -newname {$_.name.substring(0,$_.name.length-4)}
                "Renamed all files, exiting to menu."
                pause
                menu
            }
            else
            {
                Write-Host "Exiting..."
                pause
                menu
            }
    
            #$FilestoRename = dir -Path $EdgeFolder -Filter ie_to_edge* -Recurse           # gets new filenames
            #$FilestoRename | %{$_.FullName}                                               # outputs new file names
            pause
            menu
        }
}

function deleteBHO()
{
    # Checks to see if files have been deleted already, if so, exit the script, if not, continues to
    # rename all files.
    
    $FilestoDelete = findfiles
    if($FilestoDelete.Count -eq 0)
    {
        Write-Host "There are no BHO related files. Going back to menu..."
        pause
        menu
    }
        else
        {
            Write-Host "This portion of the script will delete these files. There's no going back."
            $FilestoDelete | %{$_.FullName}                                          
            ""
            if (agree("Press y to continue deletion, press any other key to exit"))
            {
                if(agree("Are you sure? You cannot revert this. Press y again to confirm, press any other key to exit."))
                {
                Write-Host "Deleting files."
                $FilestoDelete | Remove-Item
                Write-Host "Deleting all files, exiting to menu."
                menu
                }
                else
                {
                    "Exiting..."
                    pause
                    menu
                }
            }
            else
            {
                "Exiting..."
                pause
                menu
            }
            break
        }
}


###################################################################################################################################### 
# Group Policy Code

# function taken from: https://devblogs.microsoft.com/scripting/update-or-add-registry-key-value-with-powershell/
function updateRegistry($registryPath, $name, $value)
{
    if(!(Test-Path $registryPath))
    {
        New-Item -Path $registryPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -Name $name -Value $value `
        -PropertyType DWORD -Force | Out-Null
    }
        else
        {
        New-ItemProperty -Path $registryPath -Name $name -Value $value `
        -PropertyType DWORD -Force | Out-Null
        }
}


function updateGPO($num)
{
    updateRegistry "HKLM:\Software\Policies\Microsoft\Edge" "RedirectSitesFromInternetExplorerPreventBHOInstall" $num
    # https://admx.help/?Category=EdgeChromium&Policy=Microsoft.Policies.Edge::RedirectSitesFromInternetExplorerPreventBHOInstall
    updateRegistry "HKLM:\Software\Policies\Microsoft\Edge" "RedirectSitesFromInternetExplorerRedirectMode" $num
    # https://admx.help/?Category=EdgeChromium&Policy=Microsoft.Policies.Edge::RedirectSitesFromInternetExplorerRedirectMode
    Write-Host "Done, exiting to menu."
    menu
}


###################################################################################################################################### 


function agree($agreemessage)
{
    try
    {
        switch ((Read-Host -Prompt $agreemessage).Substring(0,1))
        {
            "y"
         {
                return $true
         }
            default
            {
                return $false
            }
        }
    }
    catch
    {
        return $false
    }
}

###################################################################################################################################### 

Write-Host "Disabling Edge from Opening when Internet Explorer tries to Open"
Write-Host "by hihi217"
""
Write-Host "THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
""
Write-Host "This script will rename any files related to Microsoft Edge's Internet Explorer Browser Helper Object (BHO),
either or enabling disabling Internet Explorer redirects to Edge, allowing a user to use Internet Explorer for websites
that may not function in Internet Explorer mode for Edge."
""
# Have users agree to terms before starting program, or exits otherwise.

switch ((Read-Host -Prompt "Press y to agree to terms, or type any other character to exit").Substring(0,1))
{
    "y"
    {
        getDirectory
        menu
    }
    default
    {
        "Terms not agreed to, exiting."
        exit
    }
}