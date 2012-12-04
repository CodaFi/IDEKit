##IDEKit

#About

IDEKit is a framework designed to make it easy to add programmer friendly editors to existing programs, or design a whole project based IDE.  It includes support for plugins for languages, syntax coloring, preference panels, etc...  See the release notes for more details.

It was designed to work with both 10.2 and 10.3 originally, and was built using Xcode 1.1 (targeting 10.2.7).  IDEKit was forked internally at apple, and is the basis for Xcode's editing capabilities, syntax highlighting, and project format.  It is a highly complicated framework, and as such, is a little unstable at the moment.

#What's New

This version provides stable ARC integration, upgraded Objective-C 2.0 style syntax, and a higher release target (most likely 10.5+).  I'd also like to keep development of the active and involved.  

#Contributing

We will gladly accept Pull Requests that meet one of the following criteria:

1. It fixes something that is already in IDEKit.  This might be a bug, or something that doesn't work as expected.
2. It's something so basic or important that IDEKit really should have it.
3. Documentation!

#Demo

A simple demo is included with this project.  As of yet, it does not support completion or syntax highlighting (TBI at a later date), however it does show the simplicity of the framework itself.  

#Notes
This is not a 1.0 release (there are both bugs as well as missing features), but is still quite usable as is.

#Licensing
IDEKit is distributed under LGPL, so you can use the framework as a whole in a commercial closed source project.
