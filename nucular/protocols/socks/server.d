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

module nucular.protocols.socks.server;

public import nucular.reactor : Address, InternetAddress, Internet6Address;
public import nucular.protocols.dns.resolver : UnresolvedAddress;

import std.conv;
import std.array;
import std.exception;

import nucular.connection;
import buffered = nucular.protocols.buffered;
import base = nucular.protocols.socks.base;

class Socks : buffered.Protocol
{
	alias base.SocksError SocksError;
	alias base.Socks4     Socks4;
	alias base.Socks5     Socks5;

	final override void receiveBufferedData (ref ubyte[] data)
	{
		try {
			parseRequest(data);
		}
		catch (Exception e) {
			failedRequest(e);
		}
	}

	final override void receiveUnbufferedData (ubyte[] data)
	{
		receiveProxyData(data);
	}

	void begin (string ver)
	{
		// this is just a place holder
	}

	bool authenticate (string username)
	{
		return true;
	}

	bool authenticate (string username, string password)
	{
		return true;
	}

	void methods (Socks5.Method[] methods)
	{
		// this is just a place holder
	}

	void request (Socks4.Type type, Address address)
	{
		// this is just a place holder
	}

	void request (Socks5.Type type, Address address)
	{
		// this is just a place holder
	}

	void failedRequest (Exception e)
	{
		// this is just a place holder
	}

	void failedRequest (Socks4.Reply reply)
	{
		// this is just a place holder
	}

	void failedRequest (Socks5.Reply reply)
	{
		// this is just a place holder
	}

	void receiveProxyData (ubyte[] data)
	{
		// this is just a place holder
	}

	final void sendResponse (Socks4.Reply reply)
	{
		sendData(cast (ubyte[]) [0, reply, 0, 0, 0, 0, 0, 0]);
	}

	final void sendResponse (Socks5.Reply reply)
	{

	}

	final void use (Socks5.Method method)
	{
		_method = method;

		sendData(cast (ubyte[]) [5, cast (ubyte) method]);
	}

	final @property isAuthenticated ()
	{
		return _authenticated;
	}

	final @property method ()
	{
		return _method;
	}

	final @property socksVersion ()
	{
		return _socks_version;
	}

private:
	void parseRequest (ref ubyte[] data)
	{
		if (data[0] == 4) {
			if (data.length < 9) {
				minimum = 9;

				return;
			}

			Socks4.Type type         = cast (Socks4.Type) data[1];
			ushort      port         = data[2 .. 4].fromBytes!ushort;
			uint        addr         = data[4 .. 8].fromBytes!uint;
			Address     address;
			bool        needs_host   = false;
			int         username_end = -1;

			if (addr >> 8 == 0 && addr != 0) {
				begin(_socks_version = "4a");

				needs_host = true;
			}
			else {
				begin(_socks_version = "4");
			}

			foreach (index, piece; data[8 .. $]) {
				if (piece == 0) {
					username_end = index.to!int + 1;

					break;
				}
			}

			string username = cast (string) data[8 .. 8 + username_end];

			if (needs_host) {
				int host_end = -1;

				foreach (index, piece; data[8 + username_end .. $]) {
					if (piece == 0) {
						host_end = index.to!int + 1;

						break;
					}
				}

				if (host_end == -1) {
					return;
				}

				string host = cast (string) data[8 + username_end .. 8 + username_end + host_end];
				
				address = new UnresolvedAddress(host, port);
				data    = data[8 + username_end + host_end .. $];
			}
			else {
				address = new InternetAddress(addr, port);
				data    = data[8 + username_end .. $];
			}

			if (authenticate(username)) {
				_authenticated = true;

				request(type, address);
			}
			else {
				failedRequest(Socks4.Reply.IdentdNotAuthenticated);
			}

			unbuffered = true;
		}
		else if (data[0] == 5) {
			begin(_socks_version = "5");

			if (isAuthenticated) {

			}
			else {
				if (method == Socks5.Method.NoAcceptable) {

				}
				else {
					switch (method) {
						case Socks5.Method.NoAuthenticationRequired:
							_authenticated = true;
							break;

						case Socks5.Method.UsernameAndPassword:

						default: assert (0);
					}
				}
			}
		}
		else {
			throw new SocksError("unsupported SOCKS version");
		}
	}

private:
	string _socks_version;
	bool   _authenticated;

	Socks5.Method _method;
}

class Socks4 : Socks, base.Socks4
{
	final override void begin (string ver)
	{
		enforceEx!SocksError(ver == "4", "wrong SOCKS version");
	}
}

class Socks4a : Socks, base.Socks4
{
	final override void begin (string ver)
	{
		enforceEx!SocksError(ver == "4" || ver == "4a", "wrong SOCKS version");
	}
}

class Socks5 : Socks, base.Socks5
{
	final override void begin (string ver)
	{
		enforceEx!SocksError(ver == "5", "wrong SOCKS version");
	}
}

private:
	T fromBytes(T) (ubyte[] data)
	{
		T result = 0;

		for (int i = 0; i < T.sizeof; i++) {
			result |= data[i];

			if (i != T.sizeof - 1) {
				result <<= 8;
			}
		}

		return result;
	}
