hieralookup
===========

A web service for doing hiera lookups and reverse hiera lookups

It gets facts from PuppetDB and looks up the specified hiera key.
Results are returned as JSON.

Forward lookup
--------------

/hiera/&lt;hostname&gt;/&lt;key&gt;[/&lt;resolution_type&gt;][?fact=override]

- __hostname__ is the hostname we should fetch the facts for
- __key__ is the hiera key to look up
- __resolution_type__ is optional and should be either _array_, _priority_ or _hash_ with _priority_ being the default
- Any additional URL parameters are used for overriding facts

Reverse lookup
--------------

/hiera_reverse/&lt;key&gt;/&lt;value&gt;[/&lt;resolution_type&gt;]

- __key__ is the hiera key to look up
- __value__ is the value to match
- __resolution_type__ is optional and should be either _array_, _priority_ or _hash_ with _priority_ being the default
