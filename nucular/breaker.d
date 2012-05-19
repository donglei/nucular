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

module nucular.breaker;

import core.time;

import nucular.descriptor;
import nucular.available.best;

class Breaker
{
	this ()
	{
		version (Posix) {
			import core.sys.posix.unistd;

			int[2] pair;

			pipe(pair);

			_read  = new Descriptor(pair[0]);
			_write = new Descriptor(pair[1]);
		}
		else {
			static assert(0);
		}

		_write.asynchronous = true;
		_read.asynchronous  = true;
	}

	void act ()
	{
		_write.write("x");
	}

	void flush ()
	{
		while (_read.read(1024)) {
			continue;
		}
	}

	void wait ()
	{
		readable([_read]);
	}

	void wait (Duration sleep)
	{
		readable([_read], sleep);
	}

	Descriptor opCast(T : Descriptor) ()
	{
		return _read;
	}

	// FIXME: remove when the bug is fixed
	Object opCast(T : Object) ()
	{
		return this;
	}

	override string toString ()
	{
		return "Breaker(" ~ _read.toString() ~ ", " ~ _write.toString() ~ ")";
	}

private:
	Descriptor _read;
	Descriptor _write;
}
