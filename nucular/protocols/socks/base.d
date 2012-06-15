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

module nucular.protocols.socks.base;

class SocksError : Exception
{
	this (string msg, string file = __FILE__, size_t line = __LINE__)
	{
		super(msg, file, line);
	}

	this (Socks4.Reply code)
	{
		string message;

		final switch (code) {
			case Socks4.Reply.Granted:                throw new Exception("there were no errors, why did you call this?");
			case Socks4.Reply.Rejected:               message = "rejected or failed request"; break;
			case Socks4.Reply.IdentdNotRunning:       message = "identd isn't running"; break;
			case Socks4.Reply.IdentdNotAuthenticated: message = "identd failed the authentication"; break;
		}

		super(message);
	}

	this (Socks5.Reply code)
	{
		string message;

		final switch (code) {
			case Socks5.Reply.Succeeded:               throw new Exception("there were no errors, why did you call this?");
			case Socks5.Reply.GeneralError:            message = "general Socks server failure"; break;
			case Socks5.Reply.ConnectionNotAllowed:    message = "connection not allowed by ruleset"; break;
			case Socks5.Reply.NetworkUnreachable:      message = "network unreachable"; break;
			case Socks5.Reply.HostUnreachable:         message = "host unreachable"; break;
			case Socks5.Reply.ConnectionRefused:       message = "connection refused"; break;
			case Socks5.Reply.TTLExpired:              message = "TTL expired"; break;
			case Socks5.Reply.CommandNotSupported:     message = "command not supported"; break;
			case Socks5.Reply.AddressTypeNotSupported: message = "address type not supported"; break;
		}

		super(message);
	}
}

interface Socks4
{
	enum Type
	{
		StreamConnection = 0x01,
		PortBinding
	}

	enum Reply
	{
		Granted = 0x5a,
		Rejected,
		IdentdNotRunning,
		IdentdNotAuthenticated
	}
}

interface Socks5
{
	enum State
	{
		MethodNegotiation,
		Connecting,
		Authenticating,
		Finished
	}

	enum Method
	{
		NoAuthenticationRequired,
		GSSAPI,
		UsernameAndPassword,
		ChallengeHandshakeAuthenticationProtocol,
		ChallengeResponseAuthenticationMethod = 0x05,
		SecureSocketsLayer,
		NDSAuthentication,
		MultiAuthenticationFramework,
		
		NoAcceptable = 0xFF
	}

	enum Type
	{
		Connect = 1,
		Bind,
		UDPAssociate
	}
	
	enum NetworkType
	{
		IPv4     = 0x01,
		HostName = 0x03,
		IPv6
	}

	enum Reply
	{
		Succeeded,
		GeneralError,
		ConnectionNotAllowed,
		NetworkUnreachable,
		HostUnreachable,
		ConnectionRefused,
		TTLExpired,
		CommandNotSupported,
		AddressTypeNotSupported
	}
}
