using System;
using System.Collections.Generic;
using System.Text;

namespace DataPlotter.Data
{
	public class TimeStampedValue<T>
	{
		public TimeStampedValue(DateTime timeStamp, T value)
		{
			TimeStamp = timeStamp;
			Value = value;
		}

		public readonly DateTime TimeStamp;

		public readonly T Value;
	}
}
