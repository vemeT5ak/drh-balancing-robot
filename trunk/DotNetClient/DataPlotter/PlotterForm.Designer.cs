namespace DataPlotter
{
	partial class PlotterForm
	{
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.IContainer components = null;

		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		/// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
		protected override void Dispose(bool disposing)
		{
			if (disposing && (components != null))
			{
				components.Dispose();
			}
			base.Dispose(disposing);
		}

		#region Windows Form Designer generated code

		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{
			this.components = new System.ComponentModel.Container();
			this.m_Timer = new System.Windows.Forms.Timer(this.components);
			this.m_BottomPanel = new System.Windows.Forms.Panel();
			this.m_AngleContributionTextBox = new System.Windows.Forms.TextBox();
			this.label3 = new System.Windows.Forms.Label();
			this.m_SendButton = new System.Windows.Forms.Button();
			this.m_PTextBox = new System.Windows.Forms.TextBox();
			this.label2 = new System.Windows.Forms.Label();
			this.m_RateContributionTextBox = new System.Windows.Forms.TextBox();
			this.label1 = new System.Windows.Forms.Label();
			this.m_PlotSurface2D = new NPlot.Windows.PlotSurface2D();
			this.m_ITextBox = new System.Windows.Forms.TextBox();
			this.label4 = new System.Windows.Forms.Label();
			this.m_DTextBox = new System.Windows.Forms.TextBox();
			this.label5 = new System.Windows.Forms.Label();
			this.m_AngleOffsetTestBox = new System.Windows.Forms.TextBox();
			this.label6 = new System.Windows.Forms.Label();
			this.m_BottomPanel.SuspendLayout();
			this.SuspendLayout();
			// 
			// m_Timer
			// 
			this.m_Timer.Tick += new System.EventHandler(this.OnTimerTick);
			// 
			// m_BottomPanel
			// 
			this.m_BottomPanel.Controls.Add(this.m_AngleOffsetTestBox);
			this.m_BottomPanel.Controls.Add(this.label6);
			this.m_BottomPanel.Controls.Add(this.m_DTextBox);
			this.m_BottomPanel.Controls.Add(this.label5);
			this.m_BottomPanel.Controls.Add(this.m_ITextBox);
			this.m_BottomPanel.Controls.Add(this.label4);
			this.m_BottomPanel.Controls.Add(this.m_AngleContributionTextBox);
			this.m_BottomPanel.Controls.Add(this.label3);
			this.m_BottomPanel.Controls.Add(this.m_SendButton);
			this.m_BottomPanel.Controls.Add(this.m_PTextBox);
			this.m_BottomPanel.Controls.Add(this.label2);
			this.m_BottomPanel.Controls.Add(this.m_RateContributionTextBox);
			this.m_BottomPanel.Controls.Add(this.label1);
			this.m_BottomPanel.Dock = System.Windows.Forms.DockStyle.Bottom;
			this.m_BottomPanel.Location = new System.Drawing.Point(0, 334);
			this.m_BottomPanel.Name = "m_BottomPanel";
			this.m_BottomPanel.Size = new System.Drawing.Size(623, 92);
			this.m_BottomPanel.TabIndex = 3;
			// 
			// m_AngleContributionTextBox
			// 
			this.m_AngleContributionTextBox.Location = new System.Drawing.Point(252, 6);
			this.m_AngleContributionTextBox.Name = "m_AngleContributionTextBox";
			this.m_AngleContributionTextBox.Size = new System.Drawing.Size(71, 22);
			this.m_AngleContributionTextBox.TabIndex = 9;
			this.m_AngleContributionTextBox.Text = "0";
			// 
			// label3
			// 
			this.label3.AutoSize = true;
			this.label3.Location = new System.Drawing.Point(151, 9);
			this.label3.Name = "label3";
			this.label3.Size = new System.Drawing.Size(101, 17);
			this.label3.TabIndex = 8;
			this.label3.Text = "Angle Contrib.:";
			// 
			// m_SendButton
			// 
			this.m_SendButton.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
			this.m_SendButton.Location = new System.Drawing.Point(540, 61);
			this.m_SendButton.Name = "m_SendButton";
			this.m_SendButton.Size = new System.Drawing.Size(71, 23);
			this.m_SendButton.TabIndex = 7;
			this.m_SendButton.Text = "Send";
			this.m_SendButton.UseVisualStyleBackColor = true;
			this.m_SendButton.Click += new System.EventHandler(this.m_SendButton_Click);
			// 
			// m_PTextBox
			// 
			this.m_PTextBox.Location = new System.Drawing.Point(37, 6);
			this.m_PTextBox.Name = "m_PTextBox";
			this.m_PTextBox.Size = new System.Drawing.Size(70, 22);
			this.m_PTextBox.TabIndex = 6;
			this.m_PTextBox.Text = "0";
			// 
			// label2
			// 
			this.label2.AutoSize = true;
			this.label2.Location = new System.Drawing.Point(10, 9);
			this.label2.Name = "label2";
			this.label2.Size = new System.Drawing.Size(21, 17);
			this.label2.TabIndex = 5;
			this.label2.Text = "P:";
			// 
			// m_RateContributionTextBox
			// 
			this.m_RateContributionTextBox.Location = new System.Drawing.Point(252, 34);
			this.m_RateContributionTextBox.Name = "m_RateContributionTextBox";
			this.m_RateContributionTextBox.Size = new System.Drawing.Size(71, 22);
			this.m_RateContributionTextBox.TabIndex = 4;
			this.m_RateContributionTextBox.Text = "0";
			// 
			// label1
			// 
			this.label1.AutoSize = true;
			this.label1.Location = new System.Drawing.Point(151, 37);
			this.label1.Name = "label1";
			this.label1.Size = new System.Drawing.Size(95, 17);
			this.label1.TabIndex = 3;
			this.label1.Text = "Rate Contrib.:";
			// 
			// m_PlotSurface2D
			// 
			this.m_PlotSurface2D.AutoScaleAutoGeneratedAxes = false;
			this.m_PlotSurface2D.AutoScaleTitle = false;
			this.m_PlotSurface2D.BackColor = System.Drawing.SystemColors.ControlLightLight;
			this.m_PlotSurface2D.DateTimeToolTip = false;
			this.m_PlotSurface2D.Dock = System.Windows.Forms.DockStyle.Fill;
			this.m_PlotSurface2D.Legend = null;
			this.m_PlotSurface2D.LegendZOrder = -1;
			this.m_PlotSurface2D.Location = new System.Drawing.Point(0, 0);
			this.m_PlotSurface2D.Name = "m_PlotSurface2D";
			this.m_PlotSurface2D.RightMenu = null;
			this.m_PlotSurface2D.ShowCoordinates = true;
			this.m_PlotSurface2D.Size = new System.Drawing.Size(623, 334);
			this.m_PlotSurface2D.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.None;
			this.m_PlotSurface2D.TabIndex = 4;
			this.m_PlotSurface2D.Text = "plotSurface2D1";
			this.m_PlotSurface2D.Title = "";
			this.m_PlotSurface2D.TitleFont = new System.Drawing.Font("Arial", 14F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Pixel);
			this.m_PlotSurface2D.XAxis1 = null;
			this.m_PlotSurface2D.XAxis2 = null;
			this.m_PlotSurface2D.YAxis1 = null;
			this.m_PlotSurface2D.YAxis2 = null;
			// 
			// m_ITextBox
			// 
			this.m_ITextBox.Location = new System.Drawing.Point(37, 33);
			this.m_ITextBox.Name = "m_ITextBox";
			this.m_ITextBox.Size = new System.Drawing.Size(70, 22);
			this.m_ITextBox.TabIndex = 11;
			this.m_ITextBox.Text = "0";
			// 
			// label4
			// 
			this.label4.AutoSize = true;
			this.label4.Location = new System.Drawing.Point(10, 36);
			this.label4.Name = "label4";
			this.label4.Size = new System.Drawing.Size(15, 17);
			this.label4.TabIndex = 10;
			this.label4.Text = "I:";
			// 
			// m_DTextBox
			// 
			this.m_DTextBox.Location = new System.Drawing.Point(37, 61);
			this.m_DTextBox.Name = "m_DTextBox";
			this.m_DTextBox.Size = new System.Drawing.Size(70, 22);
			this.m_DTextBox.TabIndex = 13;
			this.m_DTextBox.Text = "0";
			// 
			// label5
			// 
			this.label5.AutoSize = true;
			this.label5.Location = new System.Drawing.Point(10, 64);
			this.label5.Name = "label5";
			this.label5.Size = new System.Drawing.Size(22, 17);
			this.label5.TabIndex = 12;
			this.label5.Text = "D:";
			// 
			// m_AngleOffsetTestBox
			// 
			this.m_AngleOffsetTestBox.Location = new System.Drawing.Point(252, 61);
			this.m_AngleOffsetTestBox.Name = "m_AngleOffsetTestBox";
			this.m_AngleOffsetTestBox.Size = new System.Drawing.Size(71, 22);
			this.m_AngleOffsetTestBox.TabIndex = 15;
			this.m_AngleOffsetTestBox.Text = "0";
			// 
			// label6
			// 
			this.label6.AutoSize = true;
			this.label6.Location = new System.Drawing.Point(151, 64);
			this.label6.Name = "label6";
			this.label6.Size = new System.Drawing.Size(90, 17);
			this.label6.TabIndex = 14;
			this.label6.Text = "Angle Offset:";
			// 
			// PlotterForm
			// 
			this.AcceptButton = this.m_SendButton;
			this.AutoScaleDimensions = new System.Drawing.SizeF(8F, 16F);
			this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
			this.ClientSize = new System.Drawing.Size(623, 426);
			this.Controls.Add(this.m_PlotSurface2D);
			this.Controls.Add(this.m_BottomPanel);
			this.Name = "PlotterForm";
			this.Text = "Data Plotter";
			this.m_BottomPanel.ResumeLayout(false);
			this.m_BottomPanel.PerformLayout();
			this.ResumeLayout(false);

		}

		#endregion

		private System.Windows.Forms.Timer m_Timer;
		private System.Windows.Forms.Panel m_BottomPanel;
		private System.Windows.Forms.TextBox m_PTextBox;
		private System.Windows.Forms.Label label2;
		private System.Windows.Forms.TextBox m_RateContributionTextBox;
		private System.Windows.Forms.Label label1;
		private NPlot.Windows.PlotSurface2D m_PlotSurface2D;
		private System.Windows.Forms.Button m_SendButton;
		private System.Windows.Forms.TextBox m_AngleContributionTextBox;
		private System.Windows.Forms.Label label3;
		private System.Windows.Forms.TextBox m_DTextBox;
		private System.Windows.Forms.Label label5;
		private System.Windows.Forms.TextBox m_ITextBox;
		private System.Windows.Forms.Label label4;
		private System.Windows.Forms.TextBox m_AngleOffsetTestBox;
		private System.Windows.Forms.Label label6;
	}
}

