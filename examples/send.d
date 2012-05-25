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

import std.stdio;
import std.getopt;
import std.regex : ctRegex, match;
import std.conv;
import core.thread;

import nucular.reactor;
import line = nucular.protocols.line;

class RawSender : Connection
{
	override void receiveData (ubyte[] data)
	{
		writeln(data);
	}
}

class LineSender : line.Protocol
{
	override void receiveLine (string line)
	{
		writeln(line);
	}
}

int main (string[] args)
{
	string protocol = "tcp";
	string target   = "localhost:10000";
	bool   ipv4     = true;
	bool   ipv6     = false;
	bool   line     = false;

	getopt(args, config.noPassThrough,
		"protocol|p", &protocol,
		"t",          &target,
		"4",          &ipv4,
		"6",          &ipv6,
		"line|L",     &line);

	Address address;

	switch (protocol) {
		case "tcp":
		case "udp":
			if (auto m = target.match(ctRegex!`^(.*?):(\d+)$`)) {
				string host = m.captures[1];
				ushort port = m.captures[2].to!ushort;

				address = ipv6 ? new Internet6Address(host, port) : new InternetAddress(host, port);
			}
			break;

		version (Posix) {
			case "unix":
				address = new UnixAddress(target);
				break;

			case "fifo":
				if (auto m = target.match(ctRegex!`^(.*?):(\d+)$`)) {
					string path       = m.captures[1];
					int    permission = toImpl!int(m.captures[2], 8);

					address = new NamedPipeAddress(path, permission);
				}
				break;
		}
		
		default:
			writeln("unsupported protocol");
			return 1;
	}

	nucular.reactor.run({
		Connection connection;

		if (line) {
			connection = address.connect!LineSender;
		}
		else {
			connection = address.connect!RawSender;
		}

		(new Thread({
			char[] data;

			while (stdin.readln(data)) {
				if (line) {
					auto sender = cast (LineSender) cast (Object) connection;
					sender.sendLine(cast (string) data[0 .. data.length - 1]);
				}
				else {
					auto sender = cast (RawSender) cast (Object) connection;
					sender.sendData(cast (ubyte[]) data);
				}
			}

			nucular.reactor.stop();
		})).start();
	});

	return 0;
}
