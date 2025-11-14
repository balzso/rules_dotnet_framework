using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Resources;
using System.Text;

namespace simpleresgen
{
    public class Translator
    {
        public void Translate(string infile, string outfile)
        {
            var writer = new ResourceWriter(outfile);
            using (var reader = new ResXResourceReader(infile))
            {
                foreach (DictionaryEntry d in reader)
                {
                    writer.AddResource(d.Key.ToString(), d.Value);
                }
            }

            writer.Generate();
            writer.Close();
        }
    }
}
