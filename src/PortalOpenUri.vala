/*
 * Copyright 2017 Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

namespace Tiliado
{

[DBus (name = "org.freedesktop.portal.OpenURI")]
public class PortalOpenUri: GLib.Object
{
    private DBusConnection conn;
    private uint last_request_id = 0;
    
    public PortalOpenUri(DBusConnection conn)
    {
        this.conn = conn;
    }
    
    public void OpenURI(string parent_window, string uri, HashTable<string, Variant> options, out ObjectPath handle)
    throws GLib.Error
    {
        var request = create_request();
        handle = request.path;
        try
        {
            Gtk.show_uri(null, uri, Gdk.CURRENT_TIME);
            Idle.add(() =>
            {
                var results = new HashTable<string, Variant>(str_hash, str_equal);
                request.Response(0, results);
                return false;
            });
        }
        catch (GLib.Error e)
        {
            Idle.add(() =>
            {
                var results = new HashTable<string, Variant>(str_hash, str_equal);
                request.Response(2, results);
                return false;
            });
        }
    }
    
    private PortalRequest create_request()
    {
        
        var id = last_request_id >= uint.MAX - 1 ? 1 : last_request_id + 1;
        last_request_id = id;
        var path = "/org/freedesktop/portal/OpenURI/requests/%u".printf(id);
        var request = new PortalRequest(path);
        try
        {
            var registration_id = conn.register_object (path, request);
            Timeout.add_seconds(2 * 60, () =>
            {
                conn.unregister_object(registration_id);
                return false;
            });
        }
        catch (GLib.IOError e)
        {
            error("Could not register %s", path);
        }
        return request;
    }
}

} // namespace Tiliado

