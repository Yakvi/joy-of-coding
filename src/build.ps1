$dateFormat = "HH:mm"
function Output-Logs([String[]]$data, [string]$title = "") {
    foreach ($line in $data) {
        If ($line -match "error ") {
            [string]$m = $matches.Values[0].trim()
            $i = $line.IndexOf($m)
            $line.Substring(0, $i) | Write-Host -ForegroundColor "Red" -NoNewline
            $line.Substring($i) | Write-Host -ForegroundColor "Gray" 
        }
        elseif ($line -match "warning ") {
            [string]$m = $matches.Values[0].trim()
            $i = $line.IndexOf($m)
            $line.Substring(0, $i) | Write-Host -ForegroundColor "DarkYellow" -NoNewline
            $line.Substring($i) | Write-Host -ForegroundColor "Gray" 
        }
        elseif ($line -match "note ") {
            [string]$m = $matches.Values[0].trim()
            $i = $line.IndexOf($m)
            $line.Substring(0, $i) | Write-Host -ForegroundColor "Cyan" -NoNewline
            $line.Substring($i) | Write-Host -ForegroundColor "Gray" 
        }
        else {
            Write-Host $line
        }
    }

    if ($data -match "error") {
        Write-Host "[$(Get-Date -Format $dateFormat)]: " -ForegroundColor "Yellow" -NoNewLine 
        Write-Host "Compilation failed, " -ForegroundColor "Red" -NoNewLine
        Write-Host $title -ForegroundColor "Cyan"
    }
}

### BOOKMARK: End helper function

# NOTE: Compiler flags
$c = '-nologo','-FC'                   #Display full path of source code
# NOTE: Faster compile/runtime
$c += '-fp:fast'                       #Floating point behaviour. Precise behaviour usually unnecessary.
$c += '-fp:except-'                    #Floating point behaviour. Precise behaviour usually unnecessary.
$c += '-Gm-'                           #Enables minimal rebuild. For faster compile.
$c += '-GR-'                           #Disables run-time type information. For faster compile.
$c += '-Oi'                            #Generates intrinsic functions. For faster runtime.
# NOTE: Preprocessor directives
$c += '-DBROSS_WIN32=1'                #Compiles for Win32
# NOTE: other
$c += '-EHa-'                          #Disable exception handling, -EHsc for c++
# NOTE: Debug mode
$debug = '-DDEBUG=1', '-D_DEBUG=1'     #Basic debug defines
$debug += '-DBROSS_DEV=1'              #For debug stuff
$debug += '-Od'                        #Optimizations disabled
$debug += '-MTd'                       #Creates debug multithreaded executable
$debug += '-Zo'                        #Enhance Optimized Debugging
$debug += '-Z7'                        #Generates C 7.0–compatible debugging information.
$debug += '-WX'                        #Treats all warnings as errors (except the ones below).
$debug += '-W4'                        #Displays all warnings (except the ones below).
# NOTE: Ignoring selected warnings:
$debug += '-wd4100'                    #Unreferenced variable
$debug += '-wd4189'                    #Local variable initialized but not used
$debug += '-wd4505'                    #Unreferenced local function
# $debug += '-wd4201'                  #Nonstandard extension used: nameless struct/union
# $debug += '-wd4127'                  #
# $debug += '-wd4302'                  #pointer truncation
# $debug += '-wd4311'                  #truncation
# $debug += '-wd4838'                  #Conversion from type 1 to type 2 requires a narrowing conversion
# $debug += '-wd4456'                  #Declaration hides previous local declaration

# NOTE: linker flags, go after the source file
$linker = '/link', '-incremental:no'   #Passes linker parameters from here; Disables incremental linking of the linker
$linker += '-opt:ref'                  #Eliminates functions and data that are never referenced
# NOTE: Extra libraries for win32
$32linker = 'user32.lib','gdi32.lib'   #Creates and manipulates the standard elements of the Windows GUI. #Graphics Device Interface, used for primitive drawing functions.
# $32linker += 'kernel32.lib'
# $32linker += 'winmm.lib'
# $32linker += 'shell32.lib'
# NOTE: OpenGL GLFW and GLEW libraries
# $openGL += 'glfw3.lib'             
# $openGL += 'glew32.lib'
# $openGL += '-LIBPATH:H:\C\_Deps\Lib\GLFW'               #Extra library path: GLFW
# $openGL += '-LIBPATH:H:\C\_Deps\Lib\GLEW'               #Extra library path: GLEW
# NOTE: Extra parameters for dll linkers
$dlllinker = '-FmDLLNAME', '-LD'      #Creates a map file
# $linkerflags = '-EXPORT:FunctionsToExport'

#timeout /t 1

$srcDir = "src"
$buildDir = "build"

# Remove-Item -Path ..\$buildDir -Force -Recurse # NOTE: Clean build
if(!(Test-Path -Path ..\$buildDir)) { mkdir ..\$buildDir }
pushd ..\$buildDir
Clear
Write-Host "[$(Get-Date -Format $dateFormat)]: " -ForegroundColor "Yellow" -NoNewLine 
Write-Host "Compilation started." -ForegroundColor "Cyan"
Write-Host ""

### BOOKMARK: Actual compiler calls
$win32file = "win32_bross.cpp"

$CompileTimer = [System.Diagnostics.Stopwatch]::StartNew()
# WIN32 PLATFORM LAYER
$win32executable = & cl -O2 $c $debug ..\$srcDir\$win32file -Fmwin32_bross $linker $32linker
Output-Logs -data $win32executable -title "win32 platform layer"

#echo "WAITING FOR PDB" > lock.tmp
# DLL template
#$DLLNAME = & cl $c -Od ..\$srcDir\DLLNAME.cpp -FmDLLNAME -LD $linker $linkerflags
# Output-Logs -data $DLLNAME -title "DLLNAME dll"
#del lock.tmp

# NOTE: Compiling Diagnostics
$CompileTime = $CompileTimer.Elapsed
Write-Host 
Write-Host "[$(Get-Date -Format $dateFormat)]: " -ForegroundColor "Yellow" -NoNewLine 
Write-Host "Compilation finished in " -ForegroundColor "Cyan"              -NoNewLine
Write-Host $([string]::Format("{0:d1}s {1:d3}ms", $CompileTime.seconds, $CompileTime.milliseconds)) -ForegroundColor "Green"

popd
