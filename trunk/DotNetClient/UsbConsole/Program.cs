using System;
using System.Collections.Generic;
using System.Text;

namespace UsbConsole
{
	class Program
	{
		static void Main(string[] args)
		{
			try
			{
				using (DataReceiver dataReceiver = new DataReceiver("COM7"))
				{
					Console.ReadLine();
				}
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				Console.ReadLine();
			}
		}
	}
}
