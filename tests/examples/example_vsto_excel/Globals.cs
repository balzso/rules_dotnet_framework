using System;

namespace ExampleVstoExcel
{
    /// <summary>
    /// Global accessor for the VSTO add-in instance
    /// </summary>
    internal static class Globals
    {
        private static ThisAddIn _thisAddIn;

        /// <summary>
        /// Gets the singleton instance of the ThisAddIn class
        /// </summary>
        internal static ThisAddIn ThisAddIn
        {
            get
            {
                if (_thisAddIn == null)
                {
                    _thisAddIn = new ThisAddIn();
                }
                return _thisAddIn;
            }
            set
            {
                _thisAddIn = value;
            }
        }
    }
}
