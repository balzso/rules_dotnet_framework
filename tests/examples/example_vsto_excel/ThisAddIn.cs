using System;
using Excel = Microsoft.Office.Interop.Excel;
using Microsoft.Office.Tools.Excel;

namespace ExampleVstoExcel
{
    /// <summary>
    /// Excel VSTO Add-in entry point
    /// </summary>
    public partial class ThisAddIn
    {
        // VSTO Application property (injected by VSTO runtime)
        public Excel.Application Application => Globals.ThisAddIn.Application;
        private void ThisAddIn_Startup(object sender, System.EventArgs e)
        {
            // Add-in initialization code
            // This code runs when Excel starts and loads the add-in
            System.Diagnostics.Debug.WriteLine("Example VSTO Excel Add-in started");

            // Example: Add a custom message to the first worksheet
            try
            {
                Excel.Worksheet activeSheet = (Excel.Worksheet)this.Application.ActiveSheet;
                Excel.Range firstCell = (Excel.Range)activeSheet.Cells[1, 1];
                firstCell.Value2 = "Hello from VSTO Add-in!";
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error in startup: {ex.Message}");
            }
        }

        private void ThisAddIn_Shutdown(object sender, System.EventArgs e)
        {
            // Add-in cleanup code
            // This code runs when Excel closes
            System.Diagnostics.Debug.WriteLine("Example VSTO Excel Add-in shutting down");
        }

        #region VSTO generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InternalStartup()
        {
            this.Startup += new System.EventHandler(ThisAddIn_Startup);
            this.Shutdown += new System.EventHandler(ThisAddIn_Shutdown);
        }

        #endregion
    }
}
