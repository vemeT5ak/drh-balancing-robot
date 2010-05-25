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
using System.Globalization;
using System.Drawing;
using SvgNet.SvgTypes;
using SvgNet.SvgElements;

namespace GridBuilder.Encoder
{
	public class EncoderRing
	{
		private static readonly SvgStyle s_FilledBlack = "fill:#000000;stroke:none;fill-opacity:1";
		private static readonly SvgStyle s_FilledWhite = "fill:#ffffff;stroke:none;fill-opacity:1";

		public EncoderRing()
			: this(50, 10, 20, 0)
		{
		}

		public EncoderRing(double outerRadius, double slotLength, int slotCount, double phaseAngle)
		{
			this.OuterRadius = outerRadius;
			this.SlotLength = slotLength;
			this.SlotCount = slotCount;
			this.PhaseAngle = phaseAngle;
		}

		public double OuterRadius { get; set; }
		public double SlotLength { get; set; }
		public double SlotCount { get; set; }
		public double PhaseAngle { get; set; }

		public void InsertSvg(SvgSvgElement root, int index)
		{
			SvgGroupElement slicesGroup = new SvgGroupElement("Slices" + index.ToString());
			slicesGroup.Style = s_FilledWhite;
			root.AddChild(slicesGroup);

			InsertSlices(slicesGroup);
			// Add inner black disk
			root.AddChild(EncoderDisk.CreateCenteredCircle(this.OuterRadius - this.SlotLength, s_FilledBlack));
		}

		private void InsertSlices(SvgGroupElement group)
		{
			double angularWidth = 360.0 / this.SlotCount / 2;
			double angleOffset = angularWidth * this.PhaseAngle / 360.0;

			for (int i = 0; i < this.SlotCount; i++)
			{
				double angle = 360.0 * i / this.SlotCount + angleOffset;
				AddSlice(group, this.OuterRadius, angle, angularWidth);
			}
		}

		private void AddSlice(SvgGroupElement group, double radius, double angle, double angularWidth)
		{
			PointF firstPointOnCircle = GetPointOnCircle(radius, angle - angularWidth / 2.0);
			PointF secondPointOnCircle = GetPointOnCircle(radius, angle + angularWidth / 2.0);

			// for an explanation of the arc syntax see: http://www.codestore.net/store.nsf/unid/EPSD-5DTT4L
			string path = String.Format(
				CultureInfo.InvariantCulture,
				"M0,0 L{0},{1} A{2},{2} 0 0,1 {3},{4} z",
				firstPointOnCircle.X, firstPointOnCircle.Y, (float)radius, secondPointOnCircle.X, secondPointOnCircle.Y);

			SvgPath svgPath = new SvgPath(path);
			SvgPathElement svgPathElement = new SvgPathElement();
			svgPathElement.D = svgPath;
			group.AddChild(svgPathElement);
		}

		private PointF GetPointOnCircle(double radius, double angle)
		{
			double x = radius * Math.Cos(angle / 180.0 * Math.PI);
			double y = radius * Math.Sin(angle / 180.0 * Math.PI);

			return new PointF((float)x, (float)y);
		}
	}
}
