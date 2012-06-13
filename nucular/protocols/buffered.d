/* Copyleft meh. [http://meh.paranoid.pk | meh@paranoici.org]
 *
 * This file is part of nucular.
 *
 * nucular is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License,
 * or (at your option) any later version.
 *
 * nucular is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with nucular. If not, see <http://www.gnu.org/licenses/>.
 ****************************************************************************/

module nucular.protocols.buffered;

import std.algorithm;
import std.array;
import std.exception;

import nucular.connection;

class Protocol : Connection
{
	override void receiveData (ubyte[] data)
	{
		if (maximum > 0 && buffer.length + data.length > maximum) {
			if (dropBeginning) {
				if (data.length - buffer.length >= buffer.length) {
					buffer = data[maximum + 1 .. $];
				}
				else {
					buffer  = buffer[data.length - buffer.length .. $];
					buffer ~= data;
				}
			}
			else {
				buffer ~= data[0 .. maximum - buffer.length];
			}
		}
		else {
			buffer ~= data;
		}

		if (buffer.length >= minimum) {
			ulong old = minimum;

			receiveBufferedData(buffer);

			if (autoReset && old == minimum) {
				minimum = 0;
			}
		}
	}

	void receiveBufferedData (ref ubyte[] data)
	{
		// this is just a place holder
	}

	@property minimum ()
	{
		return _minimum;
	}

	@property minimum (ulong value)
	{
		enforce(value == 0 || maximum == 0 || maximum >= value);

		_minimum = value;
	}

	@property maximum ()
	{
		return _maximum;
	}

	@property maximum (ulong value)
	{
		enforce(value == 0 || minimum == 0 || value >= minimum);

		_maximum = value;
	}

	@property dropBeginning ()
	{
		return _drop_beginning;
	}

	@property dropBeginning (bool value)
	{
		_drop_beginning = value;
	}

	@property autoReset ()
	{
		return _auto_reset;
	}

	@property autoReset (bool value)
	{
		_auto_reset = value;
	}

	@property ref buffer ()
	{
		return _buffer;
	}

private:
	ubyte[] _buffer;

	ulong _minimum    = 0;
	bool  _auto_reset = true;

	ulong _maximum        = 0;
	bool  _drop_beginning = false;
}
