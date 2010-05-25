using System;
using System.Collections.Generic;
using System.Text;

namespace DataPlotter.Data
{
	/// <summary>
	/// Describes a circular buffer for time stamped data. It keeps the newest data
	/// up to a given age.
	/// </summary>
	/// <typeparam name="T"></typeparam>
	public interface ITimeSpanBuffer<T> : IList<TimeStampedValue<T>>
	{
		object SyncObject { get; }

		TimeSpan MaximalAge { get; }

		bool IsReady { get; }

		void AddRange(IEnumerable<TimeStampedValue<T>> values);
	}
}