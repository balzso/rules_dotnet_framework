using System;
using Shell32;
using System.ComponentModel.DataAnnotations;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace ShellComExample
{
    class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            var shell = (Shell)Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("13709620-C279-11CE-A49E-444553540000")));
            shell.Open("shell:::{26EE0668-A00A-44D7-9371-BEB064C98683}");
            Assert.IsTrue(true, "Assert always succeed");
        }
    }

    public enum SimpleEnum
    {
        [Display(Name = "Value one")]
        Value1,
        [Display(Name = "Value two")]
        Value2,
        [Display(Name = "Value three")]
        Value3
    }
}