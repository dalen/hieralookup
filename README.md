hieralookup
===========

A web service for doing hiera lookups

It gets facts from Puppet's inventory service and looks up the specified hiera key.
Results are returned as JSON.

URL format is:

/hiera/&lt;hostname&gt;/&lt;key&gt;[/&lt;resolution_type&gt;][?fact=override]

- __hostname__ is the hostname we should fetch the facts for
- __key__ is the hiera key to look up
- __resolution_type__ is optional and should be either _array_, _priority_ or _hash_ with _priority_ being the default
- Any additional URL parameters are used for overriding facts
