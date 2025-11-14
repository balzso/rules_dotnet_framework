using System;
using Excel = Microsoft.Office.Interop.Excel;
using Microsoft.Office.Tools.Excel;
using Microsoft.Office.Tools;

namespace ExampleVstoExcel
{
    /// <summary>
    /// Simple test class to verify VSTO dependencies are properly loaded
    /// </summary>
    public class SimpleVstoTest
    {
        public void TestMethod()
        {
            // Test that we can reference Office PIA types
            Excel.Application app = null;

            // Test that we can reference VSTO runtime types
            Microsoft.Office.Tools.Factory factory = null;

            // Test that we can reference System types
            System.Console.WriteLine("VSTO dependencies loaded successfully");
        }
    }
}
