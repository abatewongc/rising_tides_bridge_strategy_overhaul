Param(
    [string] $srcDirectory, # the path that contains your mod's .XCOM_sln
    [string] $sdkPath, # the path to your SDK installation ending in "XCOM 2 War of the Chosen SDK"
    [string] $gamePath, # the path to your XCOM 2 installation ending in "XCOM2-WaroftheChosen"
    [string] $config, # build configuration
    [string] $workshopDirectory # the path to the steam workshop mods directory
)

$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path
$common = Join-Path -Path $ScriptDirectory "X2ModBuildCommon\build_common.ps1"
Write-Host "Sourcing $common"
. ($common)

$builder = [BuildProject]::new("SOCIBridgeTheProgram", $srcDirectory, $sdkPath, $gamePath)

switch ($config)
{
    "debug" {
        $builder.EnableDebug()
    }
    "default" {
        # Nothing special
    }
    "" { ThrowFailure "Missing build configuration" }
    default { ThrowFailure "Unknown build configuration $config" }
}

$builder.IncludeSrc("$workshopDirectory\1134256495\Src") # wotc highlander
$builder.IncludeSrc("$workshopDirectory\1529472981\Src") # ssaat
$builder.IncludeSrc("$workshopDirectory\2534737016\Src") # dlc2 highlander
$builder.IncludeSrc("$workshopDirectory\2567230730\Src") # covert infiltration
$builder.IncludeSrc("$srcDirectory\RisingTides\Src")


$builder.AddToClean("SquadSelectAtAnyTime")
$builder.AddToClean("RisingTides")
$builder.AddToClean("LW_Tuple")
$builder.AddToClean("CovertInfiltration")

$builder.InvokeBuild()