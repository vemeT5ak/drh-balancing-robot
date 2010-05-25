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
using SvgNet.SvgElements;
using System.Drawing;

namespace GridBuilder
{
	public class CircuitBoardBase
	{
		private static readonly SvgStyle s_MinorLineStyle = "fill:none;stroke:#000000;stroke-opacity:1;stroke-width:0.05;stroke-miterlimit:4;stroke-dasharray:none";
		private static readonly SvgStyle s_NormalLineStyle = "fill:none;stroke:#000000;stroke-opacity:1;stroke-width:0.2;stroke-miterlimit:4;stroke-dasharray:none";
		private static readonly SvgStyle s_MajorLineStyle = "fill:none;stroke:#000000;stroke-opacity:1;stroke-width:0.5;stroke-miterlimit:4;stroke-dasharray:none";

		//public Page Page { get; private set; }
		//public PointF Origin { get; set; }
		public SvgSvgElement Root { get; private set; }

		public string BuildSvg(Page page)
		{
			//this.Page = page;
			//this.Origin = new PointF(page.Width / 2, page.Height / 2);

			this.Root = new SvgSvgElement(
				page.SvgLengthWidth, page.SvgLengthHeight,
				new SvgNumList(new float[] { -page.Width / 2, -page.Height / 2, page.Width, page.Height }));

			SvgGroupElement mainGroup = new SvgGroupElement("Main");
			mainGroup.Style = s_MajorLineStyle;
			this.Root.AddChild(mainGroup);

			float outerRadius = 40f;

			AddCenteredCircle(mainGroup, outerRadius);
			AddCenteredCircle(mainGroup, 24.7f);
			AddCenteredCircle(mainGroup, 7.5f);
			AddGuideLines(mainGroup, outerRadius);

			float sideLength = 59f;
			float radius = sideLength / 2f / (float)Math.Cos(30.0 / 180.0 * Math.PI);
			AddCenteredTriangle(mainGroup, sideLength, radius);
			AddCenteredCircle(mainGroup, radius);

			AddRays(mainGroup, outerRadius);

			return this.Root.WriteSVGString(true, false);
		}

		private void AddCenteredCircle(SvgGroupElement group, float radius)
		{
			SvgEllipseElement circleElement = new SvgEllipseElement(
				0, 0,
				radius, radius);

			group.AddChild(circleElement);
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

		private void AddCenteredTriangle(SvgGroupElement group, float sideLength, float radius)
		{
			float middleLineLength = sideLength * (float)Math.Cos(30 / 180.0 * Math.PI);
			float centerToBase = middleLineLength - radius;

			SvgLineElement sideLineElement1 = new SvgLineElement(
				-sideLength/2f, -centerToBase,
				sideLength/2f, -centerToBase);
			group.AddChild(sideLineElement1);

			SvgLineElement sideLineElement2 = new SvgLineElement(
				sideLength/2f, -centerToBase,
				0, middleLineLength - centerToBase);
			group.AddChild(sideLineElement2);

			SvgLineElement sideLineElement3 = new SvgLineElement(
				0, middleLineLength - centerToBase,
				-sideLength/2f, -centerToBase);
			group.AddChild(sideLineElement3);
		}

		private void AddRays(SvgGroupElement group, float radius)
		{
			double[] angles = { 90, 150, 210, 270, 330, 30 }; //, 120, 180, 240, 300 };

			foreach (double angle in angles)
			{
				SvgLineElement rayElement = new SvgLineElement(
					0, 0,
					radius * (float)Math.Cos(angle * Math.PI / 180), radius * (float)Math.Sin(angle * Math.PI / 180));
				group.AddChild(rayElement);
			}
		}
	}
}
