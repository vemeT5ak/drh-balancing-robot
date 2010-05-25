using System;
using System.Collections.Generic;
using System.Text;

namespace DataPlotter
{
	public class LineReceivedEventArgs : EventArgs
	{
		private string m_Line;

		public LineReceivedEventArgs(string line)
		{
			m_Line = line;
		}

		public string Line
		{
			get { return m_Line; }
		}
	}
}
