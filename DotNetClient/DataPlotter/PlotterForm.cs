using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using NPlot;
using DataPlotter.Data;
using System.IO.IsolatedStorage;
using System.IO;
using System.Diagnostics;
using System.Globalization;

namespace DataPlotter
{
	public partial class PlotterForm : Form
	{
		private const string c_UserDataFileName = "UserData";

		private static readonly long s_TicksPerMilliSec = TimeSpan.FromMilliseconds(1).Ticks;

		private TimeSpan m_Resolution = TimeSpan.FromMilliseconds(50);
		private TimeSpan m_MaxAllowedTimeSpan = TimeSpan.FromMinutes(30);
		private TimeSpan m_DisplayPeriod = TimeSpan.FromSeconds(30);
		private DataReceiver m_DataReceiver;
		private ITimeSpanBuffer<double[]> m_ValuesBuffer;
		private LinePlot[] m_LinePlots;
		private IsolatedStorageFile m_IsoStore = IsolatedStorageFile.GetStore(
			IsolatedStorageScope.User | IsolatedStorageScope.Assembly, null, null);

		private DateTime m_StartTime = DateTime.Now;

		public PlotterForm()
		{
			InitializeComponent();
		}

		protected override void OnCreateControl()
		{
			if (!this.DesignMode)
			{
				InitializeFromIsolatedStorage();

				int bufferSize = (int)(this.DisplayPeriod.Ticks / m_Resolution.Ticks);
				m_ValuesBuffer = TimeSpanBuffer<double[]>.Synchronized(this.DisplayPeriod, bufferSize);
				//TempFillBuffer();

				m_DataReceiver = new DataReceiver("COM7");
				//m_DataReceiver.NewDataReceived += new EventHandler<DataReceivedEventArgs>(OnNewDataReceived);
				m_DataReceiver.LineReceived += new EventHandler<LineReceivedEventArgs>(OnLineReceived);

				m_PlotSurface2D.Clear();
				InitializeLinePlots(new Color[] {Color.Red, Color.Blue});
				//InitializeLinePlots(new Color[] { Color.Red });

				m_PlotSurface2D.XAxis1 = new DateTimeAxis(m_PlotSurface2D.XAxis1);
				m_PlotSurface2D.XAxis1.NumberFormat = "mm:ss";

				m_PlotSurface2D.Title = "Tilt Values";
				m_PlotSurface2D.XAxis1.Label = "Time";
				m_PlotSurface2D.YAxis1.Label = "Magnitude";

				RefreshGraph();

				StartTimer(100);
			}
			base.OnCreateControl();
		}

		private void InitializeFromIsolatedStorage()
		{
			if (m_IsoStore.GetFileNames(c_UserDataFileName).Length == 0)
			{
				// there is no configuration file
				return;
			}
			using (IsolatedStorageFileStream userDataFile = new IsolatedStorageFileStream(c_UserDataFileName, FileMode.Open, m_IsoStore))
			{
				using (StreamReader reader = new StreamReader(userDataFile))
				{
					m_PTextBox.Text = reader.ReadLine();
					m_ITextBox.Text = reader.ReadLine();
					m_DTextBox.Text = reader.ReadLine();
					m_AngleContributionTextBox.Text = reader.ReadLine();
					m_RateContributionTextBox.Text = reader.ReadLine();
					m_AngleOffsetTestBox.Text = reader.ReadLine();
				}
			}
		}

		private void InitializeLinePlots(Color[] colors)
		{
			m_LinePlots = new LinePlot[colors.Length];
			for (int i = 0; i < colors.Length; i++)
			{
				LinePlot linePlot = new LinePlot();
				linePlot.Pen = new Pen(colors[i], 2.0f);
				m_LinePlots[i] = linePlot;
				m_PlotSurface2D.Add(linePlot);
			}
		}

		//private void TempFillBuffer()
		//{
		//    List<TimeStampedValue<float[]>> timeStampedValues = new List<TimeStampedValue<float[]>>();

		//    DateTime start = DateTime.Now - TimeSpan.FromSeconds(60);
		//    TimeSpan deltaT = TimeSpan.FromSeconds(1);

		//    for(int i = 0; i < 100; i++)
		//    {
		//        DateTime timeStamp = start.AddTicks(i * deltaT.Ticks);
		//        float[] values = new float[3];
		//        values[0] = i - 10;
		//        values[1] = i;
		//        values[2] = i + 10;

		//        timeStampedValues.Add(new TimeStampedValue<float[]>(timeStamp, values));
		//    }

		//    m_ValuesBuffer.AddRange(timeStampedValues);
		//}

		private void StartTimer(int intervalMSec)
		{
			m_Timer.Interval = intervalMSec;
			m_Timer.Enabled = true;
		}

		private void OnTimerTick(object sender, EventArgs e)
		{
			RefreshGraph();
		}

		private void RefreshGraph()
		{
			if (m_ValuesBuffer.Count == 0)
			{
				return;
			}
			DateTime now = DateTime.Now;

			double[] xValues;
			double[][] yVectors;
			lock (m_ValuesBuffer.SyncObject)
			{
				xValues = new double[m_ValuesBuffer.Count];
				yVectors = new double[m_LinePlots.Length][];

				for (int i = 0; i < m_LinePlots.Length; i++)
				{
					yVectors[i] = new double[m_ValuesBuffer.Count];
				}
				int index = 0;
				foreach (TimeStampedValue<double[]> timeStampedValues in m_ValuesBuffer)
				{
					xValues[index] = timeStampedValues.TimeStamp.Ticks;
					for (int i = 0; i < m_LinePlots.Length; i++)
					{
						yVectors[i][index] = timeStampedValues.Value[i];
						//Debug.WriteLine(timeStampedValues.Value[i]);
					}
					index++;
				}
			}

			for (int i = 0; i < m_LinePlots.Length; i++)
			{
				m_LinePlots[i].AbscissaData = xValues;
				m_LinePlots[i].OrdinateData = yVectors[i];
			}

			double xMax = xValues[xValues.Length - 1];

			m_PlotSurface2D.XAxis1.WorldMin = xMax - this.DisplayPeriod.Ticks; // now.Ticks - this.DisplayPeriod.Ticks;
			m_PlotSurface2D.XAxis1.WorldMax = xMax; // now.Ticks;

			m_PlotSurface2D.YAxis1.WorldMin = -10;
			m_PlotSurface2D.YAxis1.WorldMax = 10;

			m_PlotSurface2D.Refresh();
		}

		public TimeSpan DisplayPeriod
		{
			get
			{
				return m_DisplayPeriod;
			}
			protected set
			{
				if (value.Ticks <= 0)
				{
					throw new ArgumentException("The display period must be greater than zero.");
				}
				if (value.Ticks > m_MaxAllowedTimeSpan.Ticks)
				{
					throw new ArgumentException("The display period must be greater than " + m_MaxAllowedTimeSpan.ToString());
				}
				m_DisplayPeriod = value;
			}
		}

		private void OnLineReceived(object sender, LineReceivedEventArgs e)
		{
			string line = e.Line;
			Debug.WriteLine(line);
			lock (m_ValuesBuffer.SyncObject)
			{
				string[] stringParts = line.Split('\t');

				DateTime timeStamp = DateTime.Now;
				
				int valuesCount = stringParts.Length;
				double[] receivedValues = new double[valuesCount];

				for (int i = 0; i < valuesCount; i++)
				{
					double receivedValue = double.Parse(stringParts[i], CultureInfo.InvariantCulture);
					receivedValues[i] = receivedValue * 180.0 / Math.PI;
				}

				//receivedValues[1] += 1;

				//if (m_ValuesBuffer.Count > 1)
				//{
				//    // In order to accomplish sample and hold behavior we insert the old values with the new time stamp first
				//    TimeStampedValue<double[]> previousTimeStampedValue = m_ValuesBuffer[m_ValuesBuffer.Count - 1];
				//    TimeStampedValue<double[]> sampleAndHoldTimeStampedValue =
				//        new TimeStampedValue<double[]>(timeStamp, previousTimeStampedValue.Value);
				//    m_ValuesBuffer.Add(sampleAndHoldTimeStampedValue);
				//}

				TimeStampedValue<double[]> timeStampedValue = new TimeStampedValue<double[]>(timeStamp, receivedValues);
				m_ValuesBuffer.Add(timeStampedValue);
			}
		}

		//private void OnLineReceived(object sender, LineReceivedEventArgs e)
		//{
		//    string line = e.Line;
		//    Debug.WriteLine(line);
		//    lock (m_ValuesBuffer.SyncObject)
		//    {
		//        string[] stringParts = line.Split('\t');

		//        DateTime timeStamp = ExtractTimeStamp(stringParts[0]);

		//        int valuesCount = stringParts.Length - 1;
		//        double[] receivedValues = new double[valuesCount];

		//        for (int i = 0; i < valuesCount; i++)
		//        {
		//            double receivedValue = double.Parse(stringParts[i + 1], CultureInfo.InvariantCulture);
		//            receivedValues[i] = receivedValue;
		//        }

		//        receivedValues[1] += 1;

		//        if (m_ValuesBuffer.Count > 1)
		//        {
		//            // In order to accomplish sample and hold behavior we insert the old values with the new time stamp first
		//            TimeStampedValue<double[]> previousTimeStampedValue = m_ValuesBuffer[m_ValuesBuffer.Count - 1];
		//            TimeStampedValue<double[]> sampleAndHoldTimeStampedValue =
		//                new TimeStampedValue<double[]>(timeStamp, previousTimeStampedValue.Value);
		//            m_ValuesBuffer.Add(sampleAndHoldTimeStampedValue);
		//        }

		//        TimeStampedValue<double[]> timeStampedValue = new TimeStampedValue<double[]>(timeStamp, receivedValues);
		//        m_ValuesBuffer.Add(timeStampedValue);
		//    }
		//}

		//private DateTime ExtractTimeStamp(string milliSecsString)
		//{
		//    long milliSecs = long.Parse(milliSecsString, CultureInfo.InvariantCulture);
		//    long ticks = milliSecs * s_TicksPerMilliSec + m_StartTime.Ticks;
		//    DateTime timeStamp = new DateTime(ticks);
		//    Debug.WriteLine(timeStamp);
		//    return timeStamp;
		//}

		private void OnNewDataReceived(object sender, DataReceivedEventArgs e)
		{
			lock (m_ValuesBuffer.SyncObject)
			{
				TimeStampedValue<double[]> timeStampedValue = new TimeStampedValue<double[]>(DateTime.Now, e.ReceivedValues);
				m_ValuesBuffer.Add(timeStampedValue);
			}
		}

		private void m_SendButton_Click(object sender, EventArgs e)
		{
			using (IsolatedStorageFileStream userDataFile = new IsolatedStorageFileStream(c_UserDataFileName, FileMode.Create, m_IsoStore))
			{
				using (StreamWriter writer = new StreamWriter(userDataFile))
				{
					writer.WriteLine(m_PTextBox.Text);
					writer.WriteLine(m_ITextBox.Text);
					writer.WriteLine(m_DTextBox.Text);
					writer.WriteLine(m_AngleContributionTextBox.Text);
					writer.WriteLine(m_RateContributionTextBox.Text);
					writer.WriteLine(m_AngleOffsetTestBox.Text);
				}
			}

			m_DataReceiver.WriteLine(
				m_PTextBox.Text + " " +
				m_ITextBox.Text + " " +
				m_DTextBox.Text + " " +
				m_AngleContributionTextBox.Text + " " +
				m_RateContributionTextBox.Text + " " +
				m_AngleOffsetTestBox.Text);
		}
	}
}
