using System;
using Microsoft.Office.Tools.Ribbon;
using Excel = Microsoft.Office.Interop.Excel;

namespace ExampleVstoExcel
{
    /// <summary>
    /// Custom Ribbon UI for Excel
    /// </summary>
    public partial class Ribbon1
    {
        private void Ribbon1_Load(object sender, RibbonUIEventArgs e)
        {
            // Ribbon initialization code
        }

        /// <summary>
        /// Button click handler - inserts sample data into Excel
        /// </summary>
        private void btnInsertData_Click(object sender, RibbonControlEventArgs e)
        {
            try
            {
                Excel.Application excelApp = Globals.ThisAddIn.Application;
                Excel.Worksheet activeSheet = (Excel.Worksheet)excelApp.ActiveSheet;

                // Insert sample data
                activeSheet.Cells[1, 1] = "Name";
                activeSheet.Cells[1, 2] = "Value";
                activeSheet.Cells[2, 1] = "Sample 1";
                activeSheet.Cells[2, 2] = 100;
                activeSheet.Cells[3, 1] = "Sample 2";
                activeSheet.Cells[3, 2] = 200;

                // Format header
                Excel.Range headerRange = activeSheet.get_Range("A1", "B1");
                headerRange.Font.Bold = true;
                headerRange.Interior.Color = System.Drawing.ColorTranslator.ToOle(System.Drawing.Color.LightBlue);

                System.Windows.Forms.MessageBox.Show("Sample data inserted successfully!");
            }
            catch (Exception ex)
            {
                System.Windows.Forms.MessageBox.Show($"Error: {ex.Message}");
            }
        }

        /// <summary>
        /// Button click handler - clears the active worksheet
        /// </summary>
        private void btnClearSheet_Click(object sender, RibbonControlEventArgs e)
        {
            try
            {
                Excel.Application excelApp = Globals.ThisAddIn.Application;
                Excel.Worksheet activeSheet = (Excel.Worksheet)excelApp.ActiveSheet;

                // Clear all cells
                activeSheet.Cells.Clear();

                System.Windows.Forms.MessageBox.Show("Worksheet cleared!");
            }
            catch (Exception ex)
            {
                System.Windows.Forms.MessageBox.Show($"Error: {ex.Message}");
            }
        }
    }
}
