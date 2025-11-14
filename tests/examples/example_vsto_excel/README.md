# Example VSTO Excel Add-in

This example demonstrates how to build a simple Excel VSTO add-in using the `net_vsto_addin` Bazel rule.

## Features

- **ThisAddIn.cs**: Main add-in entry point with Startup and Shutdown handlers
- **Ribbon1.cs**: Custom Ribbon UI with buttons to insert sample data and clear worksheets
- **Globals.cs**: Global accessor for the add-in instance

## Prerequisites

1. **Windows OS** with .NET Framework 4.7.2+ installed
2. **Microsoft Office** (Excel 2016 or later)
3. **VSTO Runtime** (installed with Visual Studio or Office Developer Tools)
4. **Bazel** build system

## Building

To build the add-in:

```bash
bazel build //tests/examples/example_vsto_excel:ExampleVstoExcel.dll
```

This will compile the add-in DLL with all necessary VSTO and Office Interop references.

## Configuration Requirements

Before building, ensure your `WORKSPACE` file includes:

1. **Office PIA NuGet packages**:
   ```python
   load("@rules_dotnet_framework//tools/nuget_packages:vsto_packages.bzl", "vsto_nuget_packages")
   vsto_nuget_packages()
   ```

2. **VSTO Runtime assembly imports**:
   The build system will automatically detect VSTO runtime assemblies from your Visual Studio installation.

## Deployment

After building, you need to:

1. **Copy the DLL** to a deployment location
2. **Generate manifests** (application and deployment manifests)
3. **Sign manifests** with a code signing certificate
4. **Register the add-in** via registry entries

### Registry Registration

To manually register the add-in for testing:

```reg
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Microsoft\Office\Excel\Addins\ExampleVstoExcel]
"Description"="Example VSTO Excel Add-in"
"FriendlyName"="Example Excel Add-in"
"LoadBehavior"=dword:00000003
"Manifest"="file:///C:/path/to/ExampleVstoExcel.vsto"
```

**LoadBehavior values:**
- `0` = Unloaded
- `1` = Loaded
- `2` = Load at startup (unloaded)
- `3` = Load at startup (loaded)

## Testing

1. Build the add-in
2. Register it in the registry
3. Open Excel
4. Go to **File > Options > Add-ins > Manage COM Add-ins**
5. You should see "Example Excel Add-in" in the list
6. Check the box to enable it

## Customization

To customize the add-in:

- Modify `ThisAddIn.cs` for startup/shutdown logic
- Modify `Ribbon1.cs` for custom Ribbon buttons and commands
- Add new source files and include them in the `srcs` attribute in BUILD

## Known Limitations

This example currently requires manual configuration of:
- Office PIA dependencies
- VSTO runtime assembly references
- Strong name key file (optional but recommended)
- Code signing certificate (optional)

Future versions will automate more of this configuration based on the `office_app` and `office_version` attributes.
