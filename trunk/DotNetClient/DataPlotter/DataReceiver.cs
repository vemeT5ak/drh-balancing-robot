using System;
using System.Collections.Generic;
using System.Text;
using System.Threading;
using System.IO.Ports;
using System.Globalization;

namespace DataPlotter
{
	public class DataReceiver : IDisposable
	{
		private SerialPort m_Port;

		//private UsbPacketIO m_UsbPacketIO;
		private Thread m_ReadThread;

		public event EventHandler<DataReceivedEventArgs> NewDataReceived;
		public event EventHandler<LineReceivedEventArgs> LineReceived;

		public DataReceiver(string port)
		{
			m_Port = new SerialPort();
			m_Port.PortName = port;

			m_Port.BaudRate = 115200;

			m_Port.Open();
			//m_Port.DtrEnable = true;

			m_ReadThread = new Thread(Read);
			m_ReadThread.IsBackground = true;
			m_ReadThread.Start();
		}

		private void Read()
		{
			bool isFirstRun = true;
			string line;
			while (true)
			{
				line = m_Port.ReadLine();

				// we ignore the first packet since we don't know where we start
				if (isFirstRun)
				{
					isFirstRun = false;
					continue;
				}

				RaiseLineReceivedEvent(line);
				//double[] receivedValues = ExtractValues(line);
				//OnNewDataReceived(receivedValues);
			}
		}

		private double[] ExtractValues(string line)
		{
			string[] stringParts = line.Split('\t');
			int valuesCount = stringParts.Length - 1;
			double[] receivedValues = new double[valuesCount];

			for (int i = 0; i < valuesCount; i++)
			{
				double receivedValue = double.Parse(stringParts[i + 1], CultureInfo.InvariantCulture);
				receivedValues[i] = receivedValue;
			}

			if (String.Equals("rad", stringParts[0], StringComparison.OrdinalIgnoreCase))
			{
				for (int i = 0; i < valuesCount; i++)
				{
					receivedValues[i] = receivedValues[i] * 180.0 / Math.PI;
				}
			}

			return receivedValues;
		}

		private void OnNewDataReceived(double[] receivedValues)
		{
			// Make a temporary copy of the event handler to avoid the possibility of
			// a race condition if the last subscriber unsubscribes
			// immediately after the null check and before the event is raised.
			EventHandler<DataReceivedEventArgs> handler = NewDataReceived;

			// Event will be null if there are no subscribers
			if (handler != null)
			{
				DataReceivedEventArgs eventArgs = new DataReceivedEventArgs(receivedValues);
				handler(this, eventArgs);
			}
		}

		private void RaiseLineReceivedEvent(string line)
		{
			// Make a temporary copy of the event handler to avoid the possibility of
			// a race condition if the last subscriber unsubscribes
			// immediately after the null check and before the event is raised.
			EventHandler<LineReceivedEventArgs> handler = LineReceived;

			// Event will be null if there are no subscribers
			if (handler != null)
			{
				LineReceivedEventArgs eventArgs = new LineReceivedEventArgs(line);
				handler(this, eventArgs);
			}
		}

		public void WriteLine(string line)
		{
			m_Port.WriteLine(line);
		}

		#region IDisposable Members

		/// <summary>
		/// Disposes the object.
		/// </summary>
		public void Dispose()
		{
			Dispose(true);
		}

		/// <summary/>
		protected virtual void Dispose(bool disposing)
		{
			lock (this)
			{
				if (disposing)
				{
					GC.SuppressFinalize(this);
					if (m_Port != null)
					{
						if (m_Port.IsOpen)
						{
							m_Port.Close();
							m_Port = null;
						}
					}
					//if (m_UsbPacketIO != null)
					//{
					//    m_UsbPacketIO.Dispose();
					//}
				}
			}
		}

		/// <summary/>
		~DataReceiver()
		{
			Dispose(false);
		}

		#endregion
	}
}
