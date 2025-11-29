# Copyright (c) Microsoft Corporation.  All rights reserved.

$ErrorActionPreference = 'Stop'
$InitialDatabase = '0'

<#
.SYNOPSIS
    Adds or updates an Entity Framework provider entry in the project config
    file.

.DESCRIPTION
    Adds an entry into the 'entityFramework' section of the project config
    file for the specified provider invariant name and provider type. If an
    entry for the given invariant name already exists, then that entry is
    updated with the given type name, unless the given type name already
    matches, in which case no action is taken. The 'entityFramework'
    section is added if it does not exist. The config file is automatically
    saved if and only if a change was made.

    This command is typically used only by Entity Framework provider NuGet
    packages and is run from the 'install.ps1' script.

.PARAMETER Project
    The Visual Studio project to update. When running in the NuGet install.ps1
    script the '$project' variable provided as part of that script should be
    used.

.PARAMETER InvariantName
    The provider invariant name that uniquely identifies this provider. For
    example, the Microsoft SQL Server provider is registered with the invariant
    name 'System.Data.SqlClient'.

.PARAMETER TypeName
    The assembly-qualified type name of the provider-specific type that
    inherits from 'System.Data.Entity.Core.Common.DbProviderServices'. For
    example, for the Microsoft SQL Server provider, this type is
    'System.Data.Entity.SqlServer.SqlProviderServices, EntityFramework.SqlServer'.
#>
function Add-EFProvider
{
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [parameter(Position = 0, Mandatory = $true)]
        $Project,
        [parameter(Position = 1, Mandatory = $true)]
        [string] $InvariantName,
        [parameter(Position = 2, Mandatory = $true)]
        [string] $TypeName)

    $configPath = GetConfigPath $Project
    if (!$configPath)
    {
        return
    }

    [xml] $configXml = Get-Content $configPath

    $providers = $configXml.configuration.entityFramework.providers

    $providers.provider |
        where invariantName -eq $InvariantName |
        %{ $providers.RemoveChild($_) | Out-Null }

    $provider = $providers.AppendChild($configXml.CreateElement('provider'))
    $provider.SetAttribute('invariantName', $InvariantName)
    $provider.SetAttribute('type', $TypeName)

    $configXml.Save($configPath)
}

<#
.SYNOPSIS
    Adds or updates an Entity Framework default connection factory in the
    project config file.

.DESCRIPTION
    Adds an entry into the 'entityFramework' section of the project config
    file for the connection factory that Entity Framework will use by default
    when creating new connections by convention. Any existing entry will be
    overridden if it does not match. The 'entityFramework' section is added if
    it does not exist. The config file is automatically saved if and only if
    a change was made.

    This command is typically used only by Entity Framework provider NuGet
    packages and is run from the 'install.ps1' script.

.PARAMETER Project
    The Visual Studio project to update. When running in the NuGet install.ps1
    script the '$project' variable provided as part of that script should be
    used.

.PARAMETER TypeName
    The assembly-qualified type name of the connection factory type that
    implements the 'System.Data.Entity.Infrastructure.IDbConnectionFactory'
    interface.  For example, for the Microsoft SQL Server Express provider
    connection factory, this type is
    'System.Data.Entity.Infrastructure.SqlConnectionFactory, EntityFramework'.

.PARAMETER ConstructorArguments
    An optional array of strings that will be passed as arguments to the
    connection factory type constructor.
#>
function Add-EFDefaultConnectionFactory
{
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [parameter(Position = 0, Mandatory = $true)]
        $Project,
        [parameter(Position = 1, Mandatory = $true)]
        [string] $TypeName,
        [string[]] $ConstructorArguments)

    $configPath = GetConfigPath $Project
    if (!$configPath)
    {
        return
    }

    [xml] $configXml = Get-Content $configPath

    $entityFramework = $configXml.configuration.entityFramework
    $defaultConnectionFactory = $entityFramework.defaultConnectionFactory
    if ($defaultConnectionFactory)
    {
        $entityFramework.RemoveChild($defaultConnectionFactory) | Out-Null
    }
    $defaultConnectionFactory = $entityFramework.AppendChild($configXml.CreateElement('defaultConnectionFactory'))

    $defaultConnectionFactory.SetAttribute('type', $TypeName)

    if ($ConstructorArguments)
    {
        $parameters = $defaultConnectionFactory.AppendChild($configXml.CreateElement('parameters'))

        foreach ($constructorArgument in $ConstructorArguments)
        {
            $parameter = $parameters.AppendChild($configXml.CreateElement('parameter'))
            $parameter.SetAttribute('value', $constructorArgument)
        }
    }

    $configXml.Save($configPath)
}

<#
.SYNOPSIS
    Enables Code First Migrations in a project.

.DESCRIPTION
    Enables Migrations by scaffolding a migrations configuration class in the project. If the
    target database was created by an initializer, an initial migration will be created (unless
    automatic migrations are enabled via the EnableAutomaticMigrations parameter).

.PARAMETER ContextTypeName
    Specifies the context to use. If omitted, migrations will attempt to locate a
    single context type in the target project.

.PARAMETER EnableAutomaticMigrations
    Specifies whether automatic migrations will be enabled in the scaffolded migrations configuration.
    If omitted, automatic migrations will be disabled.

.PARAMETER MigrationsDirectory
    Specifies the name of the directory that will contain migrations code files.
    If omitted, the directory will be named "Migrations".

.PARAMETER ProjectName
    Specifies the project that the scaffolded migrations configuration class will
    be added to. If omitted, the default project selected in package manager
    console is used.

.PARAMETER StartUpProjectName
    Specifies the configuration file to use for named connection strings. If
    omitted, the specified project's configuration file is used.

.PARAMETER ContextProjectName
    Specifies the project which contains the DbContext class to use. If omitted,
    the context is assumed to be in the same project used for migrations.

.PARAMETER ConnectionStringName
    Specifies the name of a connection string to use from the application's
    configuration file.

.PARAMETER ConnectionString
    Specifies the connection string to use. If omitted, the context's
    default connection will be used.

.PARAMETER ConnectionProviderName
    Specifies the provider invariant name of the connection string.

.PARAMETER Force
    Specifies that the migrations configuration be overwritten when running more
    than once for a given project.

.PARAMETER ContextAssemblyName
    Specifies the name of the assembly which contains the DbContext class to use. Use this
    parameter instead of ContextProjectName when the context is contained in a referenced
    assembly rather than in a project of the solution.

.PARAMETER AppDomainBaseDirectory
    Specifies the directory to use for the app-domain that is used for running Migrations
    code such that the app-domain is able to find all required assemblies. This is an
    advanced option that should only be needed if the solution contains	several projects
    such that the assemblies needed for the context and configuration are not all
    referenced from either the project containing the context or the project containing
    the migrations.

.EXAMPLE
    Enable-Migrations
    # Scaffold a migrations configuration in a project with only one context

.EXAMPLE
    Enable-Migrations -Auto
    # Scaffold a migrations configuration with automatic migrations enabled for a project
    # with only one context

.EXAMPLE
    Enable-Migrations -ContextTypeName MyContext -MigrationsDirectory DirectoryName
    # Scaffold a migrations configuration for a project with multiple contexts
    # This scaffolds a migrations configuration for MyContext and will put the configuration
    # and subsequent configurations in a new directory called "DirectoryName"

#>
function Enable-Migrations
{
    [CmdletBinding(DefaultParameterSetName = 'ConnectionStringName', PositionalBinding = $false)]
    param(
        [string] $ContextTypeName,
        [alias('Auto')]
        [switch] $EnableAutomaticMigrations,
        [string] $MigrationsDirectory,
        [string] $ProjectName,
        [string] $StartUpProjectName,
        [string] $ContextProjectName,
        [parameter(ParameterSetName = 'ConnectionStringName')]
        [string] $ConnectionStringName,
        [parameter(ParameterSetName = 'ConnectionStringAndProviderName', Mandatory = $true)]
        [string] $ConnectionString,
        [parameter(ParameterSetName = 'ConnectionStringAndProviderName', Mandatory = $true)]
        [string] $ConnectionProviderName,
        [switch] $Force,
        [string] $ContextAssemblyName,
        [string] $AppDomainBaseDirectory)

    WarnIfOtherEFs 'Enable-Migrations'

    $project = GetProject $ProjectName
    $startupProject = GetStartupProject $StartUpProjectName $project

    if (!$ContextAssemblyName -and $ContextProjectName)
    {
        $contextProject = Get-Project $ContextProjectName
        $ContextAssemblyName = GetProperty $contextProject.Properties 'AssemblyName'
    }

    $params = 'migrations', 'enable', '--json'

    if ($ContextTypeName)
    {
        $params += '--context', $ContextTypeName
    }

    if ($ContextAssemblyName)
    {
        $params += '--context-assembly', $ContextAssemblyName
    }

    if ($EnableAutomaticMigrations)
    {
        $params += '--auto'
    }

    if ($MigrationsDirectory)
    {
        $params += '--migrations-dir', $MigrationsDirectory
    }

    $params += GetParams $ConnectionStringName $ConnectionString $ConnectionProviderName

    if ($Force)
    {
        $params += '--force'
    }

    # NB: -join is here to support ConvertFrom-Json on PowerShell 3.0
    $result = (EF6 $project $startupProject $AppDomainBaseDirectory $params) -join "`n" | ConvertFrom-Json

    $project.ProjectItems.AddFromFile($result.migrationsConfiguration) | Out-Null
    $DTE.ItemOperations.OpenFile($result.migrationsConfiguration) | Out-Null
    ShowConsole

    if ($result.migration)
    {
        $project.ProjectItems.AddFromFile($result.migration) | Out-Null
        $resourcesProperties = $project.ProjectItems.AddFromFile($result.migrationResources).Properties
        $project.ProjectItems.AddFromFile($result.migrationDesigner) | Out-Null
    }
}

<#
.SYNOPSIS
    Scaffolds a migration script for any pending model changes.

.DESCRIPTION
    Scaffolds a new migration script and adds it to the project.

.PARAMETER Name
    Specifies the name of the custom script.

.PARAMETER Force
    Specifies that the migration user code be overwritten when re-scaffolding an
    existing migration.

.PARAMETER ProjectName
    Specifies the project that contains the migration configuration type to be
    used. If omitted, the default project selected in package manager console
    is used.

.PARAMETER StartUpProjectName
    Specifies the configuration file to use for named connection strings. If
    omitted, the specified project's configuration file is used.

.PARAMETER ConfigurationTypeName
    Specifies the migrations configuration to use. If omitted, migrations will
    attempt to locate a single migrations configuration type in the target
    project.

.PARAMETER ConnectionStringName
    Specifies the name of a connection string to use from the application's
    configuration file.

.PARAMETER ConnectionString
    Specifies the connection string to use. If omitted, the context's
    default connection will be used.

.PARAMETER ConnectionProviderName
    Specifies the provider invariant name of the connection string.

.PARAMETER IgnoreChanges
    Scaffolds an empty migration ignoring any pending changes detected in the current model.
    This can be used to create an initial, empty migration to enable Migrations for an existing
    database. N.B. Doing this assumes that the target database schema is compatible with the
    current model.

.PARAMETER AppDomainBaseDirectory
    Specifies the directory to use for the app-domain that is used for running Migrations
    code such that the app-domain is able to find all required assemblies. This is an
    advanced option that should only be needed if the solution contains	several projects
    such that the assemblies needed for the context and configuration are not all
    referenced from either the project containing the context or the project containing
    the migrations.

.EXAMPLE
    Add-Migration First
    # Scaffold a new migration named "First"

.EXAMPLE
    Add-Migration First -IgnoreChanges
    # Scaffold an empty migration ignoring any pending changes detected in the current model.
    # This can be used to create an initial, empty migration to enable Migrations for an existing
    # database. N.B. Doing this assumes that the target database schema is compatible with the
    # current model.

#>
function Add-Migration
{
    [CmdletBinding(DefaultParameterSetName = 'ConnectionStringName', PositionalBinding = $false)]
    param(
        [parameter(Position = 0, Mandatory = $true)]
        [string] $Name,
        [switch] $Force,
        [string] $ProjectName,
        [string] $StartUpProjectName,
        [string] $ConfigurationTypeName,
        [parameter(ParameterSetName = 'ConnectionStringName')]
        [string] $ConnectionStringName,
        [parameter(ParameterSetName = 'ConnectionStringAndProviderName', Mandatory = $true)]
        [string] $ConnectionString,
        [parameter(ParameterSetName = 'ConnectionStringAndProviderName', Mandatory = $true)]
        [string] $ConnectionProviderName,
        [switch] $IgnoreChanges,
        [string] $AppDomainBaseDirectory)

    WarnIfOtherEFs 'Add-Migration'

    $project = GetProject $ProjectName
    $startupProject = GetStartupProject $StartUpProjectName $project

    $params = 'migrations', 'add', $Name, '--json'

    if ($Force)
    {
        $params += '--force'
    }

    if ($ConfigurationTypeName)
    {
        $params += '--migrations-config', $ConfigurationTypeName
    }

    if ($IgnoreChanges)
    {
        $params += '--ignore-changes'
    }

    $params += GetParams $ConnectionStringName $ConnectionString $ConnectionProviderName

    # NB: -join is here to support ConvertFrom-Json on PowerShell 3.0
    $result = (EF6 $project $startupProject $AppDomainBaseDirectory $params) -join "`n" | ConvertFrom-Json

    $project.ProjectItems.AddFromFile($result.migration) | Out-Null
    $DTE.ItemOperations.OpenFile($result.migration) | Out-Null
    $resourcesProperties = $project.ProjectItems.AddFromFile($result.migrationResources).Properties
    $project.ProjectItems.AddFromFile($result.migrationDesigner) | Out-Null
}

<#
.SYNOPSIS
    Applies any pending migrations to the database.

.DESCRIPTION
    Updates the database to the current model by applying pending migrations.

.PARAMETER SourceMigration
    Only valid with -Script. Specifies the name of a particular migration to use
    as the update's starting point. If omitted, the last applied migration in
    the database will be used.

.PARAMETER TargetMigration
    Specifies the name of a particular migration to update the database to. If
    omitted, the current model will be used.

.PARAMETER Script
    Generate a SQL script rather than executing the pending changes directly.

.PARAMETER Force
    Specifies that data loss is acceptable during automatic migration of the
    database.

.PARAMETER ProjectName
    Specifies the project that contains the migration configuration type to be
    used. If omitted, the default project selected in package manager console
    is used.

.PARAMETER StartUpProjectName
    Specifies the configuration file to use for named connection strings. If
    omitted, the specified project's configuration file is used.

.PARAMETER ConfigurationTypeName
    Specifies the migrations configuration to use. If omitted, migrations will
    attempt to locate a single migrations configuration type in the target
    project.

.PARAMETER ConnectionStringName
    Specifies the name of a connection string to use from the application's
    configuration file.

.PARAMETER ConnectionString
    Specifies the connection string to use. If omitted, the context's
    default connection will be used.

.PARAMETER ConnectionProviderName
    Specifies the provider invariant name of the connection string.

.PARAMETER AppDomainBaseDirectory
    Specifies the directory to use for the app-domain that is used for running Migrations
    code such that the app-domain is able to find all required assemblies. This is an
    advanced option that should only be needed if the solution contains	several projects
    such that the assemblies needed for the context and configuration are not all
    referenced from either the project containing the context or the project containing
    the migrations.

.EXAMPLE
    Update-Database
    # Update the database to the latest migration

.EXAMPLE
    Update-Database -TargetMigration Second
    # Update database to a migration named "Second"
    # This will apply migrations if the target hasn't been applied or roll back migrations
    # if it has

.EXAMPLE
    Update-Database -Script
    # Generate a script to update the database from its current state to the latest migration

.EXAMPLE
    Update-Database -Script -SourceMigration Second -TargetMigration First
    # Generate a script to migrate the database from a specified start migration
    # named "Second" to a specified target migration named "First"

.EXAMPLE
    Update-Database -Script -SourceMigration $InitialDatabase
    # Generate a script that can upgrade a database currently at any version to the latest version.
    # The generated script includes logic to check the __MigrationsHistory table and only apply changes
    # that haven't been previously applied.

.EXAMPLE
    Update-Database -TargetMigration $InitialDatabase
    # Runs the Down method to roll-back any migrations that have been applied to the database


#>
function Update-Database
{
    [CmdletBinding(DefaultParameterSetName = 'ConnectionStringName', PositionalBinding = $false)]
    param(
        [string] $SourceMigration,
        [string] $TargetMigration,
        [switch] $Script,
        [switch] $Force,
        [string] $ProjectName,
        [string] $StartUpProjectName,
        [string] $ConfigurationTypeName,
        [parameter(ParameterSetName = 'ConnectionStringName')]
        [string] $ConnectionStringName,
        [parameter(ParameterSetName = 'ConnectionStringAndProviderName', Mandatory = $true)]
        [string] $ConnectionString,
        [parameter(ParameterSetName = 'ConnectionStringAndProviderName', Mandatory = $true)]
        [string] $ConnectionProviderName,
        [string] $AppDomainBaseDirectory)

    WarnIfOtherEFs 'Update-Database'

    $project = GetProject $ProjectName
    $startupProject = GetStartupProject $StartUpProjectName $project

    $params = 'database', 'update'

    if ($SourceMigration)
    {
        $params += '--source', $SourceMigration
    }

    if ($TargetMigration)
    {
        $params += '--target', $TargetMigration
    }

    if ($Script)
    {
        $params += '--script'
    }

    if ($Force)
    {
        $params += '--force'
    }

    if ($ConfigurationTypeName)
    {
        $params += '--migrations-config', $ConfigurationTypeName
    }

    $params += GetParams $ConnectionStringName $ConnectionString $ConnectionProviderName

    $result = (EF6 $project $startupProject $AppDomainBaseDirectory $params) -join "`n"
    if ($result)
    {
        try
        {
            $window = $DTE.ItemOperations.NewFile('General\Sql File')
            $textDocument = $window.Document.Object('TextDocument')
            $editPoint = $textDocument.StartPoint.CreateEditPoint()
            $editPoint.Insert($result)
        }
        catch
        {
            $intermediatePath = GetIntermediatePath $project
            if (![IO.Path]::IsPathRooted($intermediatePath))
            {
                $projectDir = GetProperty $project.Properties 'FullPath'
                $intermediatePath = Join-Path $projectDir $intermediatePath -Resolve | Convert-Path
            }

            $fileName = [IO.Path]::ChangeExtension([IO.Path]::GetRandomFileName(), '.sql')
            $sqlFile = Join-Path $intermediatePath $fileName

            [IO.File]::WriteAllText($sqlFile, $result)

            $DTE.ItemOperations.OpenFile($sqlFile) | Out-Null
        }

        ShowConsole
    }
}

<#
.SYNOPSIS
    Displays the migrations that have been applied to the target database.

.DESCRIPTION
    Displays the migrations that have been applied to the target database.

.PARAMETER ProjectName
    Specifies the project that contains the migration configuration type to be
    used. If omitted, the default project selected in package manager console
    is used.

.PARAMETER StartUpProjectName
    Specifies the configuration file to use for named connection strings. If
    omitted, the specified project's configuration file is used.

.PARAMETER ConfigurationTypeName
    Specifies the migrations configuration to use. If omitted, migrations will
    attempt to locate a single migrations configuration type in the target
    project.

.PARAMETER ConnectionStringName
    Specifies the name of a connection string to use from the application's
    configuration file.

.PARAMETER ConnectionString
    Specifies the connection string to use. If omitted, the context's
    default connection will be used.

.PARAMETER ConnectionProviderName
    Specifies the provider invariant name of the connection string.

.PARAMETER AppDomainBaseDirectory
    Specifies the directory to use for the app-domain that is used for running Migrations
    code such that the app-domain is able to find all required assemblies. This is an
    advanced option that should only be needed if the solution contains	several projects
    such that the assemblies needed for the context and configuration are not all
    referenced from either the project containing the context or the project containing
    the migrations.
#>
function Get-Migrations
{
    [CmdletBinding(DefaultParameterSetName = 'ConnectionStringName', PositionalBinding = $false)]
    param(
        [string] $ProjectName,
        [string] $StartUpProjectName,
        [string] $ConfigurationTypeName,
        [parameter(ParameterSetName = 'ConnectionStringName')]
        [string] $ConnectionStringName,
        [parameter(ParameterSetName = 'ConnectionStringAndProviderName', Mandatory = $true)]
        [string] $ConnectionString,
        [parameter(ParameterSetName = 'ConnectionStringAndProviderName', Mandatory = $true)]
        [string] $ConnectionProviderName,
        [string] $AppDomainBaseDirectory)

    WarnIfOtherEFs 'Get-Migrations'

    $project = GetProject $ProjectName
    $startupProject = GetStartupProject $StartUpProjectName $project

    $params = 'migrations', 'list'

    if ($ConfigurationTypeName)
    {
        $params += '--migrations-config', $ConfigurationTypeName
    }

    $params += GetParams $ConnectionStringName $ConnectionString $ConnectionProviderName

    return EF6 $project $startupProject $AppDomainBaseDirectory $params
}

function WarnIfOtherEFs($cmdlet)
{
    if (Get-Module 'EntityFrameworkCore')
    {
        Write-Warning "Both Entity Framework 6 and Entity Framework Core are installed. The Entity Framework 6 tools are running. Use 'EntityFrameworkCore\$cmdlet' for Entity Framework Core."
    }

    if (Get-Module 'EntityFramework')
    {
        Write-Warning "A version of Entity Framework older than 6.3 is also installed. The newer tools are running. Use 'EntityFramework\$cmdlet' for the older version."
    }
}

function GetProject($projectName)
{
    if (!$projectName)
    {
        return Get-Project
    }

    return Get-Project $projectName
}

function GetStartupProject($name, $fallbackProject)
{
    if ($name)
    {
        return Get-Project $name
    }

    $startupProjectPaths = $DTE.Solution.SolutionBuild.StartupProjects
    if ($startupProjectPaths)
    {
        if ($startupProjectPaths.Length -eq 1)
        {
            $startupProjectPath = $startupProjectPaths[0]
            if (![IO.Path]::IsPathRooted($startupProjectPath))
            {
                $solutionPath = Split-Path (GetProperty $DTE.Solution.Properties 'Path')
                $startupProjectPath = Join-Path $solutionPath $startupProjectPath -Resolve | Convert-Path
            }

            $startupProject = GetSolutionProjects |
                ?{
                    try
                    {
                        $fullName = $_.FullName
                    }
                    catch [NotImplementedException]
                    {
                        return $false
                    }

                    if ($fullName -and $fullName.EndsWith('\'))
                    {
                        $fullName = $fullName.Substring(0, $fullName.Length - 1)
                    }

                    return $fullName -eq $startupProjectPath
                }
            if ($startupProject)
            {
                return $startupProject
            }

            Write-Warning "Unable to resolve startup project '$startupProjectPath'."
        }
        else
        {
            Write-Warning 'Multiple startup projects set.'
        }
    }
    else
    {
        Write-Warning 'No startup project set.'
    }

    Write-Warning "Using project '$($fallbackProject.ProjectName)' as the startup project."

    return $fallbackProject
}

function GetSolutionProjects()
{
    $projects = New-Object 'System.Collections.Stack'

    $DTE.Solution.Projects |
        %{ $projects.Push($_) }

    while ($projects.Count)
    {
        $project = $projects.Pop();

        <# yield return #> $project

        if ($project.ProjectItems)
        {
            $project.ProjectItems |
                ?{ $_.SubProject } |
                %{ $projects.Push($_.SubProject) }
        }
    }
}

function GetParams($connectionStringName, $connectionString, $connectionProviderName)
{
    $params = @()

    if ($connectionStringName)
    {
        $params += '--connection-string-name', $connectionStringName
    }

    if ($connectionString)
    {
        $params += '--connection-string', $connectionString,
            '--connection-provider', $connectionProviderName
    }

    return $params
}

function ShowConsole
{
    $componentModel = Get-VSComponentModel
    $powerConsoleWindow = $componentModel.GetService([NuGetConsole.IPowerConsoleWindow])
    $powerConsoleWindow.Show()
}

function WriteErrorLine($message)
{
    try
    {
        # Call the internal API NuGet uses to display errors
        $componentModel = Get-VSComponentModel
        $powerConsoleWindow = $componentModel.GetService([NuGetConsole.IPowerConsoleWindow])
        $bindingFlags = [Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::NonPublic
        $activeHostInfo = $powerConsoleWindow.GetType().GetProperty('ActiveHostInfo', $bindingFlags).GetValue($powerConsoleWindow)
        $internalHost = $activeHostInfo.WpfConsole.Host
        $reportErrorMethod = $internalHost.GetType().GetMethod('ReportError', $bindingFlags, $null, [Exception], $null)
        $exception = New-Object Exception $message
        $reportErrorMethod.Invoke($internalHost, $exception)
    }
    catch
    {
        Write-Host $message -ForegroundColor DarkRed
    }
}

function EF6($project, $startupProject, $workingDir, $params)
{
    $solutionBuild = $DTE.Solution.SolutionBuild
    $solutionBuild.BuildProject(
        $solutionBuild.ActiveConfiguration.Name,
        $project.UniqueName,
        <# WaitForBuildToFinish #> $true)
    if ($solutionBuild.LastBuildInfo)
    {
        throw "The project '$($project.ProjectName)' failed to build."
    }

    $projectDir = GetProperty $project.Properties 'FullPath'
    $outputPath = GetProperty $project.ConfigurationManager.ActiveConfiguration.Properties 'OutputPath'
    $targetDir = [IO.Path]::GetFullPath([IO.Path]::Combine($projectDir, $outputPath))
    $targetFrameworkMoniker = GetProperty $project.Properties 'TargetFrameworkMoniker'
    $frameworkName = New-Object 'System.Runtime.Versioning.FrameworkName' $targetFrameworkMoniker
    $targetFrameworkIdentifier = $frameworkName.Identifier
    $targetFrameworkVersion = $frameworkName.Version

    if ($targetFrameworkIdentifier -in '.NETFramework')
    {
        if ($targetFrameworkVersion -lt '4.5')
        {
            $frameworkDir = 'net40'
        }
        else
        {
            $frameworkDir = 'net45'
        }

        $platformTarget = GetPlatformTarget $project
        if ($platformTarget -eq 'x86')
        {
            $runtimeDir = 'win-x86'
        }
        elseif ($platformTarget -eq 'ARM64')
        {
            $runtimeDir = 'win-arm64'
        }
        elseif ($platformTarget -in 'AnyCPU', 'x64')
        {
            $runtimeDir = 'any'
        }
        else
        {
            throw "Project '$($project.ProjectName)' has an active platform of '$platformTarget'. Select a different " +
                'platform and try again.'
        }

        $exePath = Join-Path $PSScriptRoot "$frameworkDir\$runtimeDir\ef6.exe"
    }
    elseif ($targetFrameworkIdentifier -eq '.NETCoreApp')
    {
        $exePath = (Get-Command 'dotnet').Path

        $targetName = GetProperty $project.Properties 'AssemblyName'
        $depsFile = Join-Path $targetDir ($targetName + '.deps.json')
        $projectAssetsFile = GetCpsProperty $project 'ProjectAssetsFile'
        $runtimeConfig = Join-Path $targetDir ($targetName + '.runtimeconfig.json')
        $runtimeFrameworkVersion = GetCpsProperty $project 'RuntimeFrameworkVersion'
        $efPath = Join-Path $PSScriptRoot 'net6.0\any\ef6.dll'

        $dotnetParams = 'exec', '--depsfile', $depsFile

        if ($projectAssetsFile)
        {
            # NB: Don't use Get-Content. It doesn't handle UTF-8 without a signature
            # NB: Don't use ReadAllLines. ConvertFrom-Json won't work on PowerShell 3.0
            $projectAssets = [IO.File]::ReadAllText($projectAssetsFile) | ConvertFrom-Json
            $projectAssets.packageFolders.psobject.Properties.Name |
                %{ $dotnetParams += '--additionalprobingpath', $_.TrimEnd('\') }
        }

        if (Test-Path $runtimeConfig)
        {
            $dotnetParams += '--runtimeconfig', $runtimeConfig
        }
        elseif ($runtimeFrameworkVersion)
        {
            $dotnetParams += '--fx-version', $runtimeFrameworkVersion
        }

        $dotnetParams += $efPath

        $params = $dotnetParams + $params
    }
    else
    {
        throw "Project '$($startupProject.ProjectName)' targets framework '$targetFrameworkIdentifier'. The Entity Framework " +
            'Package Manager Console Tools don''t support this framework.'
    }

    $targetFileName = GetProperty $project.Properties 'OutputFileName'
    $targetPath = Join-Path $targetDir $targetFileName
    $rootNamespace = GetProperty $project.Properties 'RootNamespace'
    $language = GetLanguage $project

    $params += '--verbose',
        '--no-color',
        '--prefix-output',
        '--assembly', $targetPath,
        '--project-dir', $projectDir,
        '--language', $language

    if (IsWeb $startupProject)
    {
        $startupProjectDir = GetProperty $startupProject.Properties 'FullPath'
        $params += '--data-dir', (Join-Path $startupProjectDir 'App_Data')
    }

    if ($rootNamespace)
    {
        $params += '--root-namespace', $rootNamespace
    }

    $configFile = GetConfigPath $startupProject
    if ($configFile)
    {
        $params += '--config', $configFile
    }

    if (!$workingDir)
    {
        $workingDir = $targetDir
    }

    $arguments = ToArguments $params
    $startInfo = New-Object 'System.Diagnostics.ProcessStartInfo' -Property @{
        FileName = $exePath;
        Arguments = $arguments;
        UseShellExecute = $false;
        CreateNoWindow = $true;
        RedirectStandardOutput = $true;
        StandardOutputEncoding = [Text.Encoding]::UTF8;
        RedirectStandardError = $true;
        WorkingDirectory = $workingDir;
    }

    Write-Verbose "$exePath $arguments"

    $process = [Diagnostics.Process]::Start($startInfo)

    while (($line = $process.StandardOutput.ReadLine()) -ne $null)
    {
        $level = $null
        $text = $null

        $parts = $line.Split(':', 2)
        if ($parts.Length -eq 2)
        {
            $level = $parts[0]

            $i = 0
            $count = 8 - $level.Length
            while ($i -lt $count -and $parts[1][$i] -eq ' ')
            {
                $i++
            }

            $text = $parts[1].Substring($i)
        }

        switch ($level)
        {
            'error' { WriteErrorLine $text }
            'warn' { Write-Warning $text }
            'info' { Write-Host $text }
            'data' { Write-Output $text }
            'verbose' { Write-Verbose $text }
            default { Write-Host $line }
        }
    }

    $process.WaitForExit()

    if ($process.ExitCode)
    {
        while (($line = $process.StandardError.ReadLine()) -ne $null)
        {
            WriteErrorLine $line
        }

        exit
    }
}

function IsCpsProject($project)
{
    $hierarchy = GetVsHierarchy $project
    $isCapabilityMatch = [Microsoft.VisualStudio.Shell.PackageUtilities].GetMethod(
        'IsCapabilityMatch',
        [type[]]([Microsoft.VisualStudio.Shell.Interop.IVsHierarchy], [string]))

    return $isCapabilityMatch.Invoke($null, ($hierarchy, 'CPS'))
}

function IsWeb($project)
{
    $hierarchy = GetVsHierarchy $project

    $aggregatableProject = Get-Interface $hierarchy 'Microsoft.VisualStudio.Shell.Interop.IVsAggregatableProject'
    if (!$aggregatableProject)
    {
        $projectTypes = $project.Kind
    }
    else
    {
        $projectTypeGuids = $null
        $hr = $aggregatableProject.GetAggregateProjectTypeGuids([ref] $projectTypeGuids)
        [Runtime.InteropServices.Marshal]::ThrowExceptionForHR($hr)

        $projectTypes = $projectTypeGuids.Split(';')
    }

    foreach ($projectType in $projectTypes)
    {
        if ($projectType -in '{349C5851-65DF-11DA-9384-00065B846F21}', '{E24C65DC-7377-472B-9ABA-BC803B73C61A}')
        {
            return $true
        }
    }

    return $false;
}

function GetIntermediatePath($project)
{
    $intermediatePath = GetProperty $project.ConfigurationManager.ActiveConfiguration.Properties 'IntermediatePath'
    if ($intermediatePath)
    {
        return $intermediatePath
    }

    return GetMSBuildProperty $project 'IntermediateOutputPath'
}

function GetPlatformTarget($project)
{
    if (IsCpsProject $project)
    {
        $platformTarget = GetCpsProperty $project 'PlatformTarget'
        if ($platformTarget)
        {
            return $platformTarget
        }

        return GetCpsProperty $project 'Platform'
    }

    $platformTarget = GetProperty $project.ConfigurationManager.ActiveConfiguration.Properties 'PlatformTarget'
    if ($platformTarget)
    {
        return $platformTarget
    }

    # NB: For classic F# projects
    $platformTarget = GetMSBuildProperty $project 'PlatformTarget'
    if ($platformTarget)
    {
        return $platformTarget
    }

    return 'AnyCPU'
}

function GetLanguage($project)
{
    if (IsCpsProject $project)
    {
        return GetCpsProperty $project 'Language'
    }

    return GetMSBuildProperty $project 'Language'
}

function GetVsHierarchy($project)
{
    $solution = Get-VSService 'Microsoft.VisualStudio.Shell.Interop.SVsSolution' 'Microsoft.VisualStudio.Shell.Interop.IVsSolution'
    $hierarchy = $null
    $hr = $solution.GetProjectOfUniqueName($project.UniqueName, [ref] $hierarchy)
    [Runtime.InteropServices.Marshal]::ThrowExceptionForHR($hr)

    return $hierarchy
}

function GetProperty($properties, $propertyName)
{
    try
    {
        return $properties.Item($propertyName).Value
    }
    catch
    {
        return $null
    }
}

function GetCpsProperty($project, $propertyName)
{
    $browseObjectContext = Get-Interface $project 'Microsoft.VisualStudio.ProjectSystem.Properties.IVsBrowseObjectContext'
    $unconfiguredProject = $browseObjectContext.UnconfiguredProject
    $configuredProject = $unconfiguredProject.GetSuggestedConfiguredProjectAsync().Result
    $properties = $configuredProject.Services.ProjectPropertiesProvider.GetCommonProperties()

    return $properties.GetEvaluatedPropertyValueAsync($propertyName).Result
}

function GetMSBuildProperty($project, $propertyName)
{
    $msbuildProject = [Microsoft.Build.Evaluation.ProjectCollection]::GlobalProjectCollection.LoadedProjects |
        where FullPath -eq $project.FullName

    return $msbuildProject.GetProperty($propertyName).EvaluatedValue
}

function ToArguments($params)
{
    $arguments = ''
    for ($i = 0; $i -lt $params.Length; $i++)
    {
        if ($i)
        {
            $arguments += ' '
        }

        if (!$params[$i].Contains(' '))
        {
            $arguments += $params[$i]

            continue
        }

        $arguments += '"'

        $pendingBackslashs = 0
        for ($j = 0; $j -lt $params[$i].Length; $j++)
        {
            switch ($params[$i][$j])
            {
                '"'
                {
                    if ($pendingBackslashs)
                    {
                        $arguments += '\' * $pendingBackslashs * 2
                        $pendingBackslashs = 0
                    }
                    $arguments += '\"'
                }

                '\'
                {
                    $pendingBackslashs++
                }

                default
                {
                    if ($pendingBackslashs)
                    {
                        if ($pendingBackslashs -eq 1)
                        {
                            $arguments += '\'
                        }
                        else
                        {
                            $arguments += '\' * $pendingBackslashs * 2
                        }

                        $pendingBackslashs = 0
                    }

                    $arguments += $params[$i][$j]
                }
            }
        }

        if ($pendingBackslashs)
        {
            $arguments += '\' * $pendingBackslashs * 2
        }

        $arguments += '"'
    }

    return $arguments
}

function GetConfigPath($project)
{
    if (IsWeb $project)
    {
        $configFileName = 'web.config'
    }
    else
    {
        $configFileName = 'app.config'
    }

    $item = $project.ProjectItems |
        where Name -eq $configFileName |
        select -First 1

    return GetProperty $item.Properties 'FullPath'
}

Export-ModuleMember 'Add-EFDefaultConnectionFactory', 'Add-EFProvider', 'Add-Migration', 'Enable-Migrations', 'Get-Migrations', 'Update-Database' -Variable 'InitialDatabase'

# SIG # Begin signature block
# MIIoLQYJKoZIhvcNAQcCoIIoHjCCKBoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDbeCwMxGtKRttT
# ijQaHdjd2z/9CxF7jWlHbDuJIb0OjaCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
# DkyjTQVBAAAAAAOvMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjMxMTE2MTkwOTAwWhcNMjQxMTE0MTkwOTAwWjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDOS8s1ra6f0YGtg0OhEaQa/t3Q+q1MEHhWJhqQVuO5amYXQpy8MDPNoJYk+FWA
# hePP5LxwcSge5aen+f5Q6WNPd6EDxGzotvVpNi5ve0H97S3F7C/axDfKxyNh21MG
# 0W8Sb0vxi/vorcLHOL9i+t2D6yvvDzLlEefUCbQV/zGCBjXGlYJcUj6RAzXyeNAN
# xSpKXAGd7Fh+ocGHPPphcD9LQTOJgG7Y7aYztHqBLJiQQ4eAgZNU4ac6+8LnEGAL
# go1ydC5BJEuJQjYKbNTy959HrKSu7LO3Ws0w8jw6pYdC1IMpdTkk2puTgY2PDNzB
# tLM4evG7FYer3WX+8t1UMYNTAgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQURxxxNPIEPGSO8kqz+bgCAQWGXsEw
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwMDEyKzUwMTgyNjAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzci
# tW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEG
# CCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0
# MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBAISxFt/zR2frTFPB45Yd
# mhZpB2nNJoOoi+qlgcTlnO4QwlYN1w/vYwbDy/oFJolD5r6FMJd0RGcgEM8q9TgQ
# 2OC7gQEmhweVJ7yuKJlQBH7P7Pg5RiqgV3cSonJ+OM4kFHbP3gPLiyzssSQdRuPY
# 1mIWoGg9i7Y4ZC8ST7WhpSyc0pns2XsUe1XsIjaUcGu7zd7gg97eCUiLRdVklPmp
# XobH9CEAWakRUGNICYN2AgjhRTC4j3KJfqMkU04R6Toyh4/Toswm1uoDcGr5laYn
# TfcX3u5WnJqJLhuPe8Uj9kGAOcyo0O1mNwDa+LhFEzB6CB32+wfJMumfr6degvLT
# e8x55urQLeTjimBQgS49BSUkhFN7ois3cZyNpnrMca5AZaC7pLI72vuqSsSlLalG
# OcZmPHZGYJqZ0BacN274OZ80Q8B11iNokns9Od348bMb5Z4fihxaBWebl8kWEi2O
# PvQImOAeq3nt7UWJBzJYLAGEpfasaA3ZQgIcEXdD+uwo6ymMzDY6UamFOfYqYWXk
# ntxDGu7ngD2ugKUuccYKJJRiiz+LAUcj90BVcSHRLQop9N8zoALr/1sJuwPrVAtx
# HNEgSW+AKBqIxYWM4Ev32l6agSUAezLMbq5f3d8x9qzT031jMDT+sUAoCw0M5wVt
# CUQcqINPuYjbS1WgJyZIiEkBMIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
# Q29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03
# a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akr
# rnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0Rrrg
# OGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy
# 4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9
# sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAh
# dCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8k
# A/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTB
# w3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmn
# Eyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90
# lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0w
# ggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2o
# ynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsG
# AQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNV
# HSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsG
# AQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABl
# AG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKb
# C5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11l
# hJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6
# I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0
# wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560
# STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQam
# ASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGa
# J+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ah
# XJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA
# 9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33Vt
# Y5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr
# /Xmfwb1tbWrJUnMTDXpQzTGCGg0wghoJAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBf2+UZ1V35D68eblBFde4xK
# ErQLQBXaZSIuA5QJUVgxMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5¶.‚PçZn÷/G€π´JoS¬ÆÔ	kæÜ˙iÍ¨”‘v!‹≠Æd%À©qÑ[©+EnÕZtÂâ®´WYbΩ»t]˚õõ3
‘£^$ÚI;¬kx?ÿaÍÕTtq1ÀUl˘IuFœ2m∫Z˚1ßıc~f5jBç<ÛÎdñÚ}´NîßQ÷¨¸Ôe˜WBı≥æÇ¡û˙Èﬂë;mÚ1≤zﬂR|≤•:5bßB~Ùz>´£)élEBº¸JS÷ç^R]tl5kÿèõkóÙ!È¡_Û1∑£v!Øïø‰/≤Ô≠›Æ#/*Q∫≤y~e¸câœÉ°√iBûz5|ybRÛSv∂Xæ]“9∏ºF*Nû¨£Õ€∆Z&øsvé)*tˆZ´˛d∏´s≥˘ÿ∆À[Ïª~J-.v\ﬁâ2-æ∫≠¥‘-.’ª ’¥“˝ó>¢*Í…s‰JWËa^£§Ú•zíZ_h˜e0ßì[›æo©bW“ˆ3•{µ≠kñ8ªﬁŸ[”À‹à¡ﬂß[r2ù(÷ÜJØ$◊πQrıÍçx q©*5U´«tıãË◊RÀrΩˆ≥Î‹«}∂‰˙˜:u2Ö⁄KkËØﬂ©deu´NÔ˙¬Æ≠Ôe{=WO»Ÿ•7i«V≤Âïó/˘:x|L%R£®ú£+≈π^ÕÏñõzùjkƒpU‹C\3J3Éï€i˚Ò”F∫ûsç¨g≥x 4qŸÁÅƒÎÇ∆…YTè›óI#OZ8jR©UÌ¯ú˙ñ&¢ØY[ú ˘wf’ØœD¥_©ãzY]-ØÒ‹j”µ˙S.wzæ√kmmÆJ}ïìËLm•˙•ﬂïÖÓ¨÷ã_Bä≤Ò≤K3ç%,—üuΩÀ©FÙ•9E%§£%º%m.∫5»ª√éyJÑ„NvÃ¢üñ}lˇ FWy[◊[5Ω˘¢◊Œ÷æ‰’•TTÈ…R∆-¶ﬂñ¢˚≤Ë˙H’ß<“úfú*”Ú /xôm—[ñˆªÔoí'gÀø°ú$‘πËÓgZJ“—r_ﬁÜpüñ-ÎekÚˇ É8’m_4Ø¶ØSrï[ËÍe•/.g§Ø{.çr∑3©√q)ÂqçKE5RYTrEΩ[÷˙ËØ~|à„úc·à≈``®qJIT“qjqŸSj;ËΩÓGì¬„!^R^x;T¶ﬁ±g;Z|C‡–mQéìö˝çq•J4È≈F+ÒÓÃ˝yíõV2O´m-ªkt2{+Í4ÔøPùØu£#ós(«õÑ‹.ìqÓÌo^ùÀ§‡¶Ω…AME§ùöJ◊ÍØª\ôé[F)GóÀµ˙Æº ÌægØ~a%mIiJ.-]=◊Ráz; ìŸÓ◊©u”W_V€Ã…nıGq˘ÑøråDÈ 2Y¢÷±)·äæÂîe[’‡”ÛC≥]
pÙ*cq≤ƒ‚”I?%7¯6v‘º¶q‰_LŸß±Ü.∂JRµÛ[CïkJNŒ…øÃ⁄¢úû‹ŒÆ	k≠Ô¯ùú<Fì^G£Ùzd≠^xe|îd◊ƒÌp˙Y¶ós{¬*{UÌ◊ˆzÖÚ(∆›ãÛ‘ó¡´)RßBï:4 °FîU8El¢ïí˘                             hœÕﬂL|=ˇ kq™*–¨’h˙H˘Ü"Vl€ˆvƒØ9Ë•F¸ÏıfÊ!ŸJÔ[|F'ﬁ|ô£QÎ°TùÓV—ãÊ`—z3ü_	*û'öä÷•%∑vøcsàÜ&íúå≤⁄€ô…∆‚'ä¨ÿW¸8ÈRKüdm–•T‘bíEãQã‚hCN”“q˜'˜_ÏWÇƒŒ5%á≈Z5Væ®ﬂNÈícR§i”sõÀÓŒKïN!S4Ô	ﬁ˝NÑ"¢¥FH2BÏ&y[µ©çHB≠9B™ÕønË÷•9‡™«YÊÉWÖNO±æø©\àıF2qÑ%)º±[≥Q_5:â™Q˜c˙≥f6Z[BV‰7°5≠á*miÕ≠iæ›àÖIQƒKâ…„E)^2k™f¬`|HÁ‘∆§„NúßQ⁄1˛Ïi¡Œ¥≥’≤èŸÖΩﬂÍ^å÷æ°≈´›Ñ˙ÈÿéÎ˙ô=û√ïô≤"QåÈJùXÊ•&Æü^´πE)ÀR4+K=)iNÆ◊Ï˚õV”B2Ωm∞‰ÌcÆüØÃÜÆÙÊbı}}:Wî¢º:ZTz6æœı&ï(QVÇ“◊◊ôõQú\*√=9/4n‰R´,4ï
≥œFnÙÍ>v‰˚£aÍ∑!•~¸í‰CK•ÌÆÊ6ÎøÍ-Î˝ÛÂﬁ÷2Qø°]jäñT≠*í’G¢ÍÕx”jÌk'Ô>eêM›•∂§+Gt›¥-É≥Ù◊BÕ≤§›ùÌm…V∂©>Òd«ÀØ•≠ﬁ˝â©Nû"ìßU∏∑§*≠‡ˇ n®÷Np™¯ú±¨µ—›MuOôùπÍÔª!ß™’æhÖÂ≈öM%≠æHŒ2¥ﬁΩÙ3Ñ¨€V¥[µˆ±≥Nµ¥—yuÙ˛ı70ÿ…AÁUìMÊrk„˚ö–qºW°Oá¯≥ˇ .£'Q)ªÁóÌ—U
≠'âú™·¢Ì}«“_π÷VÀ∫}»∂é˚≥[~oB-}â∑T…[Ïˇ êŸk–òØ6ª%´dSQØQ”ªÑÓ•Mr©£vÏ˙u&î'
~]≥Ì%∫k∫-œSƒ≤ç”o√VÀÈÃ≤.^ïD¢≠)e[w∞MI(©-˜é›üƒ∆Î+“Õnõπ);}îﬂ]ƒRé),ÚtÎ““ù\ªvóTjS©%VTj«%hÔˆªß–∂÷m?í∫¸∫µ“Î‘…n˘kw¶ÜQÍ∂3ãWÃ˜Ó_
˘y¥[ı]Ó˜Ó]à‚’)aÚ”Pç;µCH∆V›s¯≥…œ„Õ•<ïﬁ”Ÿ;Óôª√e
TûT¸*–~h?œ∫}MœÃ-Ö¥–%»ï±)a≤J2I6Ì•ïÓÓ_ö1î°¸ëÛjök[>∫€}åöVy'Yß%xÀma%÷˚=∑‘¶Ì›Õ∂ﬁØïÃl≠ŒÀ©+πíNÃiËk8º=Â è8Ó„Èÿ∫2Rç„fâÓÆJ	|IKvM¨ªôÑíwr!ÔÎ» úm+ß/É∫≤.ámãÈÍÆ[Ry"∫ÏsÎVÒ%hıV}veQæÔÒËm·ó≈˛ß[]93πÜú0¯j∏äœ¯t†Í4πÿÛ~Õ‚øÃË÷≠%ˇ Q99M-7w”Ú¯√Ç“SƒRO›îï˚#Ëü·˜ÑGè„˛÷WI ΩiapÆ⁄(Ô6ø¯£Ì                              »ƒÕÉ·‹N›o7¯Ø‘¸˚^•X”áΩ9(Øâ◊À.*å!˛úá˙jÀ&û∂8ÿçﬂ©ß=omä[wÎco¢–¿Ç>§l”[£õâ•,Ib∞±Ú‹§ñâuF8ﬁ!‚SÖÕR§oô}ï˚ñ`p Ö%ÕõtÄ"¬›ÏaZÑ+√$Ïö÷9≈˛≈XzÚÖ_új≠ü).®€î£πÕ®≈+∂˘ôŒ|B¢¥máã—_~ÏﬁßN0“7≤3[Ô°$•À~Ñ>åïÅ|G„ËF¡sŸøÃéw∂ùåjB5iJçUzmﬁÀìÎÍj–´<-eáƒ^Q~ÂE≥]˜∑c5‹ùí›æH“◊4ıXhÎ˛◊simd¥%Àn§zën¨ä‘ñ&í•6„(ª¬kxæ˝å0òâ) Ü%e≠|•›v7É¸Le(¬.SíåVÌÚ4Sñ"¶yiÓGıı/≤≥∞W‰e˙ÈÒ2ÓûÑ;r€°)%≠Ø©+µÔ`∂ÿ.»úªˆ1îa(NùXg•=”{>´π≠ÀR4´∑*S√©◊≥ËÕ¥∑ÿÜ-€B—˜[Tyïú˘¬9.›Ó›€Íd›€æ‰ØÔR≈∏NÇú$µè_ŸïEÀ	8¬¨≥Qõ¥*>O£Ól´5¶àe◊kêï¥ÊCV◊‰JV€O_Ã¬ΩX“çÏ‹•Ó∆◊øCRîdú¶›ÍK\≈Ù’›Èæz#,™ÛΩ”V≤πöã®∫5≤{ê†õíZ>Hï	%™iµ´Óg•€k[Í◊42Ÿµ≤◊ô+›Ÿ\JØIRÆûö¬qﬁ∑Ïk≈ŒùO´‚Ì‚[ ÷’TZ“{+v1i%Ê”ø3>JÀê—'£∂»F˜k3^Î[ﬂß‰Qä≠ü¯qªá€iÔŸA5µ-§¨ﬁÕIeî^©Æ‰∆/¥Õ,7.nüg€π¥öjÍÕ5r-ÿÜπu˝≈öΩ—ï¥÷‰Z˜0´Ô¯U#(.r{_t˚Æ∆t¢·(…∆-fÃ≤ËÙÂŸÆ_a˘öröúgiytR}{K™+î<◊Y^eªV¯2#nñìŸﬂ‰XÍ∂€®£ôÈx´'’7v“∑õ†y[nÌ_kÍE›≠vïåk“ßà¶£VYgr¢^hø’Òú·[Í¯ú™≠≥FQ÷3]WÏ]“€ø»Ö˙ôk}wÓJ€gª¯ô^Õ°Áå\îs;&ˆ]ŸÖUYπ^È√U≠Ø™|ùÃ!J1m8§˘5≠å™RÜ"+∆ºe‰´Ø˙Æ≈™JT´/:Z>R]Q≤¨”Û¸âK{íêÊ&6n:∆+2W|ªñ')EK42Ω%u§¥›Ú€2qnRãQÑ≠g◊¸zsW˘ïÍüuÛı0À˜uD•tdÇΩ«ŸwÒ(ú&ÂAy^Æ™˝ã!8Œ9ì”ëí2]I¸©¡Ω5”ª≥∫"Ëv.å.≥G¶•ëH∂2±≠à¨€Vi∆ˆ≥ÁŸÙ5mÂo2ΩÓ˜EÙ‚˜ﬂ°ªÜäZŸ€π◊¡≈6ñªŸı±±ÌeCŸÏBﬁUÌE[´z˛Úúª·>–T√VÚ”õˇ „+~NœÊ}ueÇ·<CM⁄•:N0”yÀ ó‚~å˙<‡ãŸﬂbx? £Rù:∫oR^i~g°                              <ß“ûqaxï;^T‘j«≥L¸µ√i9q®'ßÖör¯"Ó øàı◊ëe„a°SõçΩ»ƒs4gªËU#C—ˇ zòÛà‰aR¢ß)=9ÿJib*Ut„MT˜c˙õ∂$èÜÑ€@˚l=EâQ"Ω
xä^[©-iÕo’uÙ9ïibq›L£íïõQ⁄}ªJ¶≠ekzíÑyôØ»≈ÓFÃ…[Qn¢›4"˙lÊMªw–8s[Nî+Sï*ã4[øxæ®’°ZXZãävãªÖW≥ESõ«‘À«Òõ˝çÿ•e¢]9œq˝Í¸Ù	r¸åí‹îÆ∫òW°
Ù“®‹erß8C5yF´√‚t¨∂|¶∫£jVå\§‘bµmÚ9Ær∆’ŒØ~^Mæ¨ÿä ¨å££ÿ…≈2 ﬁÜP’t|˚ô$µ–îæakæ‹Ìπ)+\Gmvı&ÃÜª(∆tÂ
±œN[«Ø~∆¨eS5K‹©M⁄ï_ΩŸ˜6ÌÃr+´S¬—+Õ≠∫.Â	6€ìm˜2\ı"+¶´Ú,åuıÍY£”±*ï9F§s”ñÒ|Õ|≥¡€4≥·€≤ìﬁÓ˝Õ•™M=‰-Ú"€≥
≥TiÊíÕ—_viß7')…π?¿±≈∂öµ˙ø‘ )µ¢zıÿÕÍÆíY^‰¬II6ï÷ªÓYe'iß}Ù¸âãîbíìilŸ*˜∫—ÓOŸzi˙êï∂–;Ú"qÖzNï{¯{∆Q˜†˙«ˆ(Éù*8ñü8Mh¶π|{®˙∏›˜1≤ﬂwÀªçÙç≠˝ÍW^zdá˛¶πv(Z≠Ì2é∑æÖÙ„e∆≈‘ﬁV≥YÚi≠´Ry–åûΩa{∏~ËŸÑ„QfÉN/ôï¥‰-oPíomRâÀ≈nù9®€FﬁâˆFO:´¢À{8´›jù◊°l•R.*TÂ$◊'◊‰X†•‚:V∂Ó+Mzÿ≈EYÍÌndZ˛¶QZkˇ ^⁄á¯µ∞Z3¬i∫u#öko’>L÷º∞ÛTÎÀ4e§*ÚíÔ—ˆ6øwπ<Æø‰Öœ‘îõπ2ñUô´Ú]Ÿäñ}'¶gi'…v,ß/$©ø2ìMﬂG¶Õw¸ÔbºæWmy?¯‰Lw1´J°ñ•ÙŸ≠„›Bs£5NΩö{T‰Ì˙õ*Õ_Æ§≠á°À{TûX€VïÌﬁ‹ÀcNNqtkIei√I'm<ª¸Dºµ%,±åØv©T∫Kì_ÿ∆—PÀ*Jˇ y=-“¡YEkßM…”‡©ÿh˘Ñó'qø"§´%πEZ2åùJ	9}®}ÔŸôQ™™+«ì÷˚ß—ñr'ry\é™ˆ±á;2c’R_{{D'uÓ»‘≠WÏßø3Zrœ+ﬂ[C[fÁ¯Rµó‚o–˘3≠√’⁄¯4çol'y`∞ë÷Nı-›˘c˘øëÃˆ„‡”ßèßΩMØ∫Ù>üÙa√%Ìmog®KÕC∆X¨cÈ
<øıI§~ôìºõÍ»                              58∂c8V7’’Z3è‡œ»ÒØJó∂í¡®e©,,úù˜üKz"¨|â5–’√O˝JOöÃΩQ°ãVîó#B¶Â,≈ê˜ «r%eîJ
™Nz≈j£◊∏îoriÍö{Æ}L≠Ë> ãâZ_C$aZ¢•⁄ª‰ó6i(WSxä≥ºûí¶∂K∑sb/2∫wObGpÆe}π
÷2O∏VÍJA˛ ïkﬁ‰√s$ë^2ç,FTÎ˚õß˜_SK È ÇTöñ]∫õPä≥ø#n€oÿ%”[u2Zﬂ‘…%» )>WÓdëV+M≤ºea5ºYÕ®Ò5ÎCâJ0¶Ø7˛ßGËnE(F—–îO6πs±ú^ÆÔb]öM|¬V÷Ô‰JΩŸ+ùêJ¸…Hîª\Z˚°kn-£"t·Vú©’äï9nø^Ã—Ñ•Å™©b$ÂBo¯u_ˇ kËÀÒ8ÖI®SY´KhÙ]YL#d€wì›ô-˝”8≈Ôoü3%ﬂëúcßÓYß?â6ª◊‚MñYFIJ2Vq{4iJ3¿ø+u0èf˜ßŸˆÓmA©E8¥Óå1°BûiÓÙåW6hµ)∑:ÆÚ{vFqZ~êç÷ñ⁄ﬁ¶nÌ6æ&pç¢∂ÙtÌÍJJÔß-K“Ã$:ã\[ÊEñ÷–ö¥È◊•*USt€∫w÷/™ÓkFu0µcKiFn‘Î%e/^åÿ›i{u1 €zøÔëUj™9£~›4H◊å|≠t38´ΩÓ]ÎôdcÆã^ÃŒ÷2ç”∫5kQùJ∂7ãWù˘«ˆ-°V©FpwLÕ-:˛°k∂•™∑‰¢ˆWr‹äPRÀ(¥ù˝Ÿ.~•∞ã£¶õª”Us5Î•˜π:©_ù∑3mI^÷ó>‰.¡%»X=á^Ñ•°!
î•N§sB[ß˝ËÕ&Í`€çY:ò≥V⁄«¥øsn-4ú]”ÊJKì"Rå"‰ÔÈÃäsnnj7VVW≤ø5–óFYRÚΩrΩtıÊcz∑˝Ïfó?u¸…J˙ÓeóKs1ï8ŒÖEö/tÕtßÖvõœE˚≤Áœ˜6Z8ª›sçõIkkô∆-$Æ‰‚Ó¨ØæMnô+"I⁄Ko+Mv¯r%K “©≠whÎ~ó˝L6Ωë)æ™ˇ ô$Æ⁄A=àiÿëÃ¢Ω):¥ûZÀMvöËˇ r0ıºXµfßiEÓô}íÿõrÊÙ^¶K]j∑◊r- Ã≤|ÀË∆ˆ:#°°«Ò™ç“§ØZRÚÆãõ8¯r≈ŒT◊ñ≤ﬁõ›˜ã7´]ˆhÿÑt/ßÀcvÜ÷;\.9ßhÆüN6.¨q˛Ÿ;;¬ïHA/ˆ∆RãG¶ñü¬V¬÷WU`„Ø¶üâ˜†ˇ bÎ{Ï]|J)ql_Òq	k·EÎw¸_v}                            ‡$Ø±¯ªÈ)ÀÅ}-bs¶ïJK˝è˙3{âŸ÷îìÚæg•G	©«G{]§≥≠•©Õ®µe2ÿ∆⁄Ω&csºG≥ô2Z4a%}Qî%õNh…≠ Ê≈Ωºò©8”ÉìkNM⁄Ê¨#9À≈¨íñ—KÏØ‹ÀSK√m?u˛Ω+ÏJ[ë`ê[irT~b›Ö≠rn"˜ª—í∫˛Hõ-9ÿ ⁄|Ïh◊õƒ‘ï8]ROÃ˘?Â#"§óá∆⁄Y-—t}€´Ÿ˛®Û&÷˝:ñ∂‘…/âîV¸Ã¢∑&<ÓÉ—;ÿÊU≈x∏€Qäù8F’&ó…w.^m∂3KMBè¿…/ÅîVˆπ.;ÓÆßÙ&ŒÏîº£übW!eÍJVBƒòŒ´FtÍ¡J›3õO-j™˘ÆÔﬁπK£Îπúa}πñ∆:[ëí\ˆ%-:$Jÿ0õã—]ZÕ=né}xÀá U(¡œ
ıt÷}ªSoQ‚*%´F)›Eer◊Ø5πù(ﬁNÍÂ±^WBÀZÃò´lJI™ªAsC‡O ñ˙ãhKA8F≠)S©*rﬁ/Ûı4ßÄú)Vì©BN–™˘?ª#<V%©:8{9øz\†øs^îr´^Zsz≥aA[Må„¥_’S8£4¥&… ∫Íkb0“ïW_‘k}®øvßÏÃpÿàVN*Íq“Qz4 ±î€ßFZ-%/–∆›Ø√Sb1ﬂO{°dtM[À”πö[Ú'{íñèB	–"l±(4ù‘íî^È´‹Á’¶¯|ºJNr¡ﬁÚéÓüÓãÂâ•1®‰≤ÀX€ôL%:ÓÓ*œkr6S‰Ìm=yôEÈm~N?Û‘ò∆˙lgm	~§i»+Y¶ì] 'M—m“ªá8Ù1xöVä¶‘Á-¢ûﬁ•¥‡™⁄wìãyg;]≈.´ßÊXñ[ÂﬂD˙4π}ÖÌ•Ï∫ÔS◊$ñ¿ï‹-Ã∑π=¬–õ\\◊≈QuZùdØuΩügÿÀQ÷ß,—púß∫e≤ŸÊJ÷∫wÿ≈sø‡eß˜©d#w©∑F;j¬ç)NM$∫û^ÖGç∆÷≈Iﬁ7…Mv[≤Æ#√€˛%¬¨·%‘ﬂ·’é†Û¨∏ä~ZëÔ‘ËArZó“O‡m·ìøßCπÑú0ÿJıÁÂPãëÊ=èOéû.Zπ)’wÂöYW·ﬁpù14ˇ ‹ü‚~©£˛Ö+Ôí?ëò                           π ...Eœ…_‚ª'∑ƒSi<N
ùgoºõçˇ ëÖƒ,W√’ZπSM≥õà˜öæ∑)•W2tﬁœTQUjÓµ5ﬂ;òv#ôErªxí Ω’ª˝vVJ…r1fhck#∂≥iô”ño˜sÓen¡-ÏJπÖjë£	N[#Vî'ZßçàM[‹¶˛œSb⁄µsïÙ"åº9dó∏ˆ}Üà∂¸»kì‹ïÛ”rÃíW‚e‰€Ò'mç,EY’´*4[çïÂ%•ªzñ¬*1∂Øñ∫∂D¥OR®ßJYñ›àµ%xÎs$∑ÊJI.∆I]2w2A~Ü:¥™OÍ‘§’‰ÌÓÆ•î0Ò•F4·Ó≠~/ôåR•&ö˛◊”–ÿQ[Ô‹[}≈üBb¥&ﬂ!k.c/]{ã|Öí%~ îHKFkbÒ*ÑQsüŸQÊÕ>
≥©<Ewj‹£}7h+_K>hπAnM∫ì≤%?òLû@ãîcq√–îßf≠µŒv
§´QÖ‡‡µ ∫Æ¶Ù)hùΩkWæ·+.» +Bm~ÑãN·l¯ÇR∆j2ß(‘JPjÕ=ô∆¢®“ùZ4%umÎ‹›£NÈ=ô∞°oS$¥2HŒƒı u#cOâPçHJ≤üáZ1∂uˆóFi·“öÜMö¸Nï:ymΩ◊>ÜYwæÆ˚ô•Ω¬DÇW>†-¥ÿ-â[n€ò!ª'wßsœ‚ï5ƒT0T‹ÔÔB;.ËÍ‡‘eB3ß$”ﬁËø-ÓŸîc©îc°úbâÂÿándi©BvwΩ¨q±5©,k €kœóUÎc≥J§]Nõ≤îV´[˙ı!•eµπ5£!-5Ω…Hõ[ö%nJ€∞⁄¸ÇŸí ªlF∂7O	M ZΩífÑ(caõ˙ô?5l„—˜7xäx™yÈË÷íÉﬁ,ÿKC$]Mv6‚ÏöÊyÔi1“q˙Ω,ﬁ$ù≠n¶«√*PVÚ+'}ﬂ7ﬂSw¬ÕdŒ£Sàé7º—˜◊&ªùÏ&û7	Ù6í’t|—πN6ππÜWíV2ˆ∑ú”ÉµZÌB?ﬂ»{+ES¿‘ùíRí¶öÈó˜=é|m5Ω⁄V¯ü©°˛ú?⁄ø"E≈≈…                        \ ∏π"‚‰\ãüïø≈√o€,nˇ ŒGÖˆ+„pEΩ7bÏMî•™”óËh…ﬁoW”ö2Œ™'≠ÁÕyËÙ+léF.ÔÀ-ÑT!ñ#ëã1fv–≈ﬁ∆6ÁY	Á—˚»…÷´
Prõ≤FùrƒUÒÒi'¸:mÌ›õoΩ—c¥d-ıÂ¯ë(¨∫-h‘ﬁI˚Ω[ÿÿjœëfØpˆaJÍdëíCoCKY’©‡—o3˜§πR•
QPéﬂôûâw#sEZﬂ>∆õíŸÍ”‰l¬JQ∫ˇ ÇRvl ( ⁄ì‘”≈Wì®®PK≈ó7¥WVeÖ°
ÏµîùÂ'ºüRÓ\Ã$Øs7ßÓón∑∫w÷	tÿ»ïÃË 1Xà–•)K(¡·Û€àèÒdÔÙè~ÊÍÓa(ÎxÓM9ÁOØC=à
€≠©$r*ƒ◊ç
nSæäÁ/Bßö≠](—Z∆?xÍ îl¥J›Ö7ug§ëïÖû¢ƒ•¶ÑÇ,JÓ%l?1‘Ü“›•Ò9¨MLUwá¬>ŒKëπá·‘®–»ï›Ôõù˙óAYeïõ\˙ñ•Ú	r.có`aRqÑ[ñÀSçZUxùwNõîhGﬁë‘Ü8x%Ef∑'Ã∫6îo‘êë6#ë vAlIæ∆[ò¸Gƒâ<±mËéF;*≥TpﬁiΩ47∏v8HIÀÕVKÕ&]:y'û˜\ôúZñﬂ.ÜIâ∂Ø°ëJVNÔCóâƒœSÍ¯k9Àw +´7∏~JZ‘z \ŸñO	πS^W´èÍå‚Û%(›¶5Mß£'”rV€ÄZGÊ$_S[âéìîü°°√0Ú∆V˙Ó&ÍwßÆn˛áYÏh‚”Ñ˛±ÖÚ÷è K£60X™x™nQÚ :JtÕîæe{L¸:úØdØ£<∆¯Œ!S5Âß§m∂n_#ªGH•–⁄É›Ë€“›Ã+”U!(4úN¨¯'qï˛©UÍ∫¬ûYÂù7xΩSÍç‹$|Í˜Íp˝Ø≈xºgÜZ√OƒówΩæv=/
£ınÜ√Ω·ôı{∑ÛlÙ>œªÒ<7zë¸œ’“1]ó‰H  ≈≈…                    » p@π"‰\ãër3ò¸π˛,„j2Î√„ˇ ﬂ#Â_G¯óW¢ﬁç\Ô„íNYØe˝¸Œ}WÀ-Ù⁄˙Œßá,–ìøBÈIN
qŸî≤πÀ-€ÿ∫ú2-WôÓfbG#F-n`ˆ1é€òµﬁ‹Ô–‘ß≈#(‘rß)B)≈i!Ñã«µà≠˛å_‡˛”ÍŒã\ålcoC°πÑíkaJ´Ñ≤T˜y>Üœƒùu÷‰4ÌfBV%m±)+∑3KàñÜµZﬂî{≥<=(—•ï<œõÊÀk‘áÆﬂ±:5÷⁄ÿ¬I>k‘≠^õº4Ê˝™rSW].Ô»±s%X‹Lîï+5i~Ã∞¥
rMÊ©'yÕÓﬂÏl_@∂πè-]Ã\oæ∆1rá/+¸o•—(ó© ∂ s$£àÖ9MÏi‡ÈOR8™◊I;”èNÁHí%ku–òœìzô"BÿíåUx–¶Â7¢‘ÊP•.!W≈≠ôa”ºb˘ùh+$ó#/âå„”q]ŸËÃø∫$+u–ÄdG[…@∆sI^Á#â´ã≠ı|+V˚RËt0XXai(«Ysì›≥cs˝DdıR˘ôÑJÊG aVjmª#ïR§Òı›*-™KﬁüÏu0Ùa