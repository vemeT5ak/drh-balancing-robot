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
using System.Drawing;
using SvgNet.SvgElements;
using SvgNet.SvgTypes;
using System.Globalization;

namespace GridBuilder.Encoder
{
	public class EncoderDisk
	{
		private static readonly SvgStyle s_MinorLineStyle = "fill:none;stroke:#000000;stroke-opacity:1;stroke-width:0.05;stroke-miterlimit:4;stroke-dasharray:none";
		private static readonly SvgStyle s_NormalLineStyle = "fill:none;stroke:#000000;stroke-opacity:1;stroke-width:0.1;stroke-miterlimit:4;stroke-dasharray:none";
		private static readonly SvgStyle s_MajorLineStyle = "fill:none;stroke:#000000;stroke-opacity:1;stroke-width:0.2;stroke-miterlimit:4;stroke-dasharray:none";

		private static readonly SvgStyle s_FilledBlack = "fill:#000000;stroke:none;fill-opacity:1";
		private static readonly SvgStyle s_FilledWhite = "fill:#ffffff;stroke:none;fill-opacity:1";

		public EncoderDisk(double outerRadius, double centerHoleRadius)
		{
			this.OuterRadius = outerRadius;
			this.CenterHoleRadius = centerHoleRadius;
		}

		public double OuterRadius { get; set; }
		public double CenterHoleRadius { get; set; }
		public EncoderRing OuterEncoderRing { get; set; }
		public EncoderRing InnerEncoderRing { get; set; }

		public string BuildSvg(Page page)
		{
			SvgSvgElement root = new SvgSvgElement(
				page.SvgLengthWidth, page.SvgLengthHeight,
				new SvgNumList(new float[] { -page.Width / 2, -page.Height / 2, page.Width, page.Height }));

			root.AddChild(CreateCenteredCircle(this.OuterRadius, s_FilledBlack));

			// Add encoder rings
			AddEncoderRing(root, this.OuterEncoderRing, 1);
			AddEncoderRing(root, this.InnerEncoderRing, 2);

			root.AddChild(CreateCenteredCircle(this.CenterHoleRadius, s_FilledWhite));

			SvgGroupElement crossLinesGroup = new SvgGroupElement("CrossLines");
			crossLinesGroup.Style = s_NormalLineStyle;
			root.AddChild(crossLinesGroup);
			AddGuideLines(crossLinesGroup, (float)this.CenterHoleRadius);

			return root.WriteSVGString(true, false);
		}

		private void AddEncoderRing(SvgSvgElement root, EncoderRing encoderRing, int index)
		{
			if (encoderRing == null)
			{
				return;
			}

			encoderRing.InsertSvg(root, index);
		}

		internal static SvgEllipseElement CreateCenteredCircle(double radius, SvgStyle style)
		{
			SvgEllipseElement circleElement = new SvgEllipseElement(
				0, 0,
				(float)radius, (float)radius);

			circleElement.Style = style;
			return circleElement;
		}

		private void AddGuideLines(SvgGroupElement group, float radius)
		{
			SvgLineElement verticalLineElement = new SvgLineElement(
				0, radius,
				0, -radius);
			group.AddChild(verticalLineElement);

			SvgLineElement horizontalLineElement = new SvgLineElement(
				-radius, 0,
				radius, 0);
			group.AddChild(horizontalLineElement);
		}
	}
}
