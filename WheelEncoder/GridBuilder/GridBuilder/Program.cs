/****************************************************************************
Copyright (c) 2010 Dr. Rainer Hessmer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using SvgNet.SvgTypes;
using System.IO;
using GridBuilder.Encoder;

namespace GridBuilder
{
	class Program
	{
		static void Main(string[] args)
		{
			try
			{
				Page page = new Page(215, 279, SvgLengthType.SVG_LENGTHTYPE_MM);

				CircuitBoardBase circuitBoardBase = new CircuitBoardBase();
				string svgText = circuitBoardBase.BuildSvg(page);
				Save(svgText, "CircuitBoardBase.svg");

				double outerRadius = 37;
				double slotLength = 12;
				int slotCount = 40;
				double edgeOffset = 0.3;

				EncoderDisk encoderDisk = new EncoderDisk(outerRadius, 4);
				encoderDisk.OuterEncoderRing = new EncoderRing(outerRadius - edgeOffset, slotLength, slotCount, 0);
				encoderDisk.InnerEncoderRing = new EncoderRing(outerRadius - edgeOffset - slotLength, slotLength, slotCount, 180);

				svgText = encoderDisk.BuildSvg(page);
				Save(svgText, "EncoderDisk.svg");

			}
			catch (Exception ex)
			{
				Console.WriteLine(ex.ToString());
			}
			finally
			{
				Console.WriteLine("Done");
				Console.ReadLine();
			}
		}

		private static void Save(string svgText, string filePath)
		{
			using (StreamWriter writer = new StreamWriter(filePath, false))
			{
				writer.Write(svgText);
			}
		}
	}
}
