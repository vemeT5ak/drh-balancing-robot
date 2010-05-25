using System;
using System.Collections.Generic;
using System.Text;

namespace DataPlotter
{
	public class DataReceivedEventArgs : EventArgs
	{
		private double[] m_ReceivedValues;

		public DataReceivedEventArgs(double[] receivedValues)
		{
			m_ReceivedValues = receivedValues;
		}

		public double[] ReceivedValues
		{
			get { return m_ReceivedValues; }
		}
	}
}
