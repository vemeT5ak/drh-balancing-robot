/*
  TiltCalculator.h - Based on the code from Trammell Hudson (see below)
  Adapted by Dr. Rainer Hessmer, February, 2010.
*/

/* 1 dimensional tilt sensor using a dual axis accelerometer
 * and single axis angular rate gyro.  The two sensors are fused
 * via a two state Kalman filter, with one state being the angle
 * and the other state being the gyro bias.
 *
 * Gyro bias is automatically tracked by the filter.  This seems
 * like magic.
 *
 * Please note that there are lots of comments in the functions and
 * in blocks before the functions.  Kalman filtering is an already complex
 * subject, made even more so by extensive hand optimizations to the C code
 * that implements the filter.  I've tried to make an effort of explaining
 * the optimizations, but feel free to send mail to the mailing list,
 * autopilot-devel@lists.sf.net, with questions about this code.
 *
 * 
 * (c) 2003 Trammell Hudson <hudson@rotomotion.com>
 *
 *************
 *
 *  This file is part of the autopilot onboard code package.
 *  
 *  Autopilot is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *  
 *  Autopilot is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *  
 *  You should have received a copy of the GNU General Public License
 *  along with Autopilot; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

#ifndef TiltCalculator_h
#define TiltCalculator_h

#include "WProgram.h"

class TiltCalculator
{
	public:
		TiltCalculator();

		/*
		 * UpdateState is called every DeltaT with a biased gyro measurement
		 * by the user of the module.  It updates the current angle and
		 * rate estimate.
		 *
		 * The pitch gyro measurement should be scaled into real units, but
		 * does not need any bias removal.  The filter will track the bias.
		 *
		 * Our state vector is:
		 *
		 *	X = [ Angle, gyro_bias ]
		 *
		 * It runs the state estimation forward via the state functions:
		 *
		 *	Xdot = [ angle_dot, gyro_bias_dot ]
		 *
		 *	angle_dot	= gyro - gyro_bias
		 *	gyro_bias_dot	= 0
		 *
		 * And updates the covariance matrix via the function:
		 *
		 *	Pdot = A*P + P*A' + Q
		 *
		 * A is the Jacobian of Xdot with respect to the states:
		 *
		 *	A = [ d(angle_dot)/d(angle)     d(angle_dot)/d(gyro_bias) ]
		 *	    [ d(gyro_bias_dot)/d(angle) d(gyro_bias_dot)/d(gyro_bias) ]
		 *
		 *	  = [ 0 -1 ]
		 *	    [ 0  0 ]
		 *
		 * Due to the small CPU available on the microcontroller, we've
		 * hand optimized the C code to only compute the terms that are
		 * explicitly non-zero, as well as expanded out the matrix math
		 * to be done in as few steps as possible.  This does make it harder
		 * to read, debug and extend, but also allows us to do this with
		 * very little CPU time.
		 */
		void UpdateState(float pitchGyroMeasurement, float deltaT);

		/*
		 * UpdateKalman is called by a user of the module when a new
		 * accelerometer measurement is available.  ax_m and az_m do not
		 * need to be scaled into actual units, but must be zeroed and have
		 * the same scale.
		 *
		 * This does not need to be called every time step, but can be if
		 * the accelerometer data are available at the same rate as the
		 * rate gyro measurement.
		 *
		 * For a two-axis accelerometer mounted perpendicular to the rotation
		 * axis, we can compute the angle for the full 360 degree rotation
		 * with no linearization errors by using the arctangent of the two
		 * readings.
		 *
		 * As commented in state_update, the math here is simplified to
		 * make it possible to execute on a small microcontroller with no
		 * floating point unit.  It will be hard to read the actual code and
		 * see what is happening, which is why there is this extensive
		 * comment block.
		 *
		 * The C matrix is a 1x2 (measurements x states) matrix that
		 * is the Jacobian matrix of the measurement value with respect
		 * to the states.  In this case, C is:
		 *
		 *	C = [ d(angle_m)/d(angle)  d(angle_m)/d(gyro_bias) ]
		 *	  = [ 1 0 ]
		 *
		 * because the angle measurement directly corresponds to the angle
		 * estimate and the angle measurement has no relation to the gyro
		 * bias.
		 */
		void UpdateKalman(float measuredAngleRad);
		float MeasuredAngleRad; // readonly, only persisted to allow for simpler reporting
		float AngleRad; // readonly
		float AngularRateRadPerSec; // readonly
	private:
		/*
		 * Our covariance matrix.  This is updated at every time step to
		 * determine how well the sensors are tracking the actual state.
		 */
		float _covariance[2][2];
		
		// The gyro bias
		float _AngularRateBias;

		/*
		 * The angle jitter represents the measurement covariance noise.  In this case,
		 * it is a 1x1 matrix that says that we expect 0.3 rad jitter
		 * from the accelerometer.
		 */
		// !!! Adjusting the jitter value changes the speed at which the filter converges.
		//     It is an indication of trust in the measurement
		float _AccelAngleJitter;

		/*
		 * Q is a 2x2 matrix that represents the process covariance noise.
		 * In this case, it indicates how much we trust the acceleromter
		 * relative to the gyros.
		 */
		 // originally .001 and .003
		float _Q_angle;
		float _Q_gyro;

};

#endif
