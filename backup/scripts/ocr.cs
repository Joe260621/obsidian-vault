// Windows OCR tool - reads image from clipboard, outputs text
// Compile: C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /out:ocr.exe /target:exe ocr.cs
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Threading.Tasks;
using System.Windows.Forms;
using Windows.Graphics.Imaging;
using Windows.Media.Ocr;
using Windows.Storage;
using Windows.Storage.Streams;

class OcrTool
{
    [STAThread]
    static void Main(string[] args)
    {
        try
        {
            // 1. Read image from clipboard
            if (!Clipboard.ContainsImage())
            {
                Console.WriteLine("ERROR: No image in clipboard");
                Environment.Exit(1);
            }
            var img = Clipboard.GetImage();
            string tempFile = Path.Combine(Path.GetTempPath(), "ocr_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".png");
            img.Save(tempFile, ImageFormat.Png);
            Console.WriteLine("Image: " + img.Width + "x" + img.Height + " -> " + tempFile);

            // 2. OCR
            string text = RunOcrAsync(tempFile).GetAwaiter().GetResult();
            Console.WriteLine("=== OCR ===");
            Console.WriteLine(text);
            if (string.IsNullOrWhiteSpace(text))
                Console.WriteLine("(No text found)");

            // Cleanup
            File.Delete(tempFile);
        }
        catch (Exception ex)
        {
            Console.WriteLine("ERROR: " + ex.Message);
            Environment.Exit(2);
        }
    }

    static async Task<string> RunOcrAsync(string filePath)
    {
        var file = await StorageFile.GetFileFromPathAsync(filePath);
        var stream = await file.OpenReadAsync();
        var decoder = await BitmapDecoder.CreateAsync(stream);
        var bitmap = await decoder.GetSoftwareBitmapAsync();
        var engine = OcrEngine.TryCreateFromUserProfileLanguages()
                     ?? OcrEngine.TryCreateFromLanguage("en");
        if (engine == null)
            throw new Exception("OCR engine not available");
        var result = await engine.RecognizeAsync(bitmap);
        return string.Join("\n", result.Lines);
    }
}
