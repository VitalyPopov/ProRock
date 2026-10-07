# Third-party notices

ProRock itself has no third-party code dependencies: it uses the Delphi RTL only.

Some generated units are derived from published XML schemas. ProRocket translates a schema into a Delphi metamodel unit: types,
elements and attributes keep the schema's names and structure; schema comments and documentation are not carried over. Each
generated unit carries its generation date in the header. The notices of the original schemas follow.

| Unit | Derived from | Notice |
|---|---|---|
| `ProRock.Xmlite.Schema.Base` | XML Schema, https://www.w3.org/2001/XMLSchema.xsd | [W3C](#w3c) |
| `ProRock.Xmlite.Schema.Instance` | XML Schema Instance, https://www.w3.org/2001/XMLSchema-instance | [W3C](#w3c) |
| `ProRock.Xmlite.Schema.Xml` | XML namespace, https://www.w3.org/2009/01/xml.xsd | [W3C](#w3c) |
| `ProRock.Xmlite.Schema.Envelope` | SOAP 1.1 envelope, http://schemas.xmlsoap.org/soap/envelope/ | [W3C](#w3c) |
| `ProRock.Xmlite.Schema.Envelope12` | SOAP 1.2 envelope, http://www.w3.org/2003/05/soap-envelope | [W3C](#w3c) |
| `ProRock.Xmlite.Schema.Wsdl` | WSDL 1.1, http://schemas.xmlsoap.org/wsdl/2003-02-11.xsd | [IBM and Microsoft, WSDL](#ibm-and-microsoft-wsdl) |
| `ProRock.Xmlite.Schema.Soap` | WSDL SOAP 1.1 binding, http://schemas.xmlsoap.org/wsdl/soap/2003-02-11.xsd | [IBM and Microsoft, WSDL](#ibm-and-microsoft-wsdl) |
| `ProRock.Xmlite.Schema.Soap12` | WSDL SOAP 1.2 binding, http://schemas.xmlsoap.org/wsdl/soap12/wsdl11soap12.xsd | [IBM and Microsoft, SOAP 1.2 binding](#ibm-and-microsoft-soap-12-binding) |

Samples:
- `Samples/ProRock.Soapite.Calculator/calculator.wsdl` - the WSDL of the public demo service http://www.dneonline.com/calculator.asmx,
  included to demonstrate client generation
- `Samples/ProRock.Soapite.CheckVatService/checkVatService.wsdl` - the WSDL of the EU VIES VAT number validation service
  (European Commission), https://ec.europa.eu/taxation_customs/vies/checkVatService.wsdl, included to demonstrate client generation

---

## W3C

Copyright © 2001, 2003 World Wide Web Consortium, (Massachusetts Institute of Technology, European Research Consortium for
Informatics and Mathematics, Keio University). All Rights Reserved. http://www.w3.org/Consortium/Legal/

The SOAP 1.1 envelope schema also carries: Portions © 2001 DevelopMentor.

These schemas are governed by the W3C Software License, http://www.w3.org/Consortium/Legal/copyright-software-19980720:

> By obtaining, using and/or copying this work, you (the licensee) agree that you have read, understood, and will comply with the
> following terms and conditions:
>
> Permission to use, copy, modify, and distribute this software and its documentation, with or without modification, for any
> purpose and without fee or royalty is hereby granted, provided that you include the following on ALL copies of the software and
> documentation or portions thereof, including modifications, that you make:
>
> 1. The full text of this NOTICE in a location viewable to users of the redistributed or derivative work.
> 2. Any pre-existing intellectual property disclaimers, notices, or terms and conditions. If none exist, a short notice of the
>    following form (hypertext is preferred, text is permitted) should be used within the body of any redistributed or derivative
>    code: "Copyright © 2001 World Wide Web Consortium, (Massachusetts Institute of Technology, Institut National de Recherche en
>    Informatique et en Automatique, Keio University). All Rights Reserved. http://www.w3.org/Consortium/Legal/"
> 3. Notice of any changes or modifications to the W3C files, including the date changes were made. (We recommend you provide URIs
>    to the location from which the code is derived.)
>
> THIS SOFTWARE AND DOCUMENTATION IS PROVIDED "AS IS," AND COPYRIGHT HOLDERS MAKE NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO, WARRANTIES OF MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE OF THE
> SOFTWARE OR DOCUMENTATION WILL NOT INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS, TRADEMARKS OR OTHER RIGHTS.
>
> COPYRIGHT HOLDERS WILL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF ANY USE OF THE
> SOFTWARE OR DOCUMENTATION.
>
> The name and trademarks of copyright holders may NOT be used in advertising or publicity pertaining to the software without
> specific, written prior permission. Title to copyright in this software and any associated documentation will at all times remain
> with copyright holders.

---

## IBM and Microsoft, WSDL

> Copyright 2001 - 2005, International Business Machines Corporation and Microsoft Corporation
> All Rights Reserved
>
> License for WSDL Schema Files
>
> The Authors grant permission to copy and distribute the WSDL Schema Files in any medium without fee or royalty as long as this
> notice and license are distributed with them. The originals of these files can be located at:
>
> http://schemas.xmlsoap.org/wsdl/2003-02-11.xsd (WSDL), http://schemas.xmlsoap.org/wsdl/soap/2003-02-11.xsd (SOAP 1.1 binding)
>
> THESE SCHEMA FILES ARE PROVIDED "AS IS," AND THE AUTHORS MAKE NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED, REGARDING
> THESE FILES, INCLUDING, BUT NOT LIMITED TO, WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT OR
> TITLE. THE AUTHORS WILL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF OR
> RELATING TO ANY USE OR DISTRIBUTION OF THESE FILES.
>
> The name and trademarks of the Authors may NOT be used in any manner, including advertising or publicity pertaining to these files
> or any program or service that uses these files, written prior permission. Title to copyright in these files will at all times
> remain with the Authors.
>
> No other rights are granted by implication, estoppel or otherwise.

---

## IBM and Microsoft, SOAP 1.2 binding

> Copyright 2001 - 2006, International Business Machines Corporation and Microsoft Corporation
> All Rights Reserved
>
> License for WSDL 1.1 Binding Extension for SOAP 1.2 Schema Files
>
> The Authors grant permission to copy and distribute the WSDL 1.1 Binding Extension for SOAP 1.2 Schema Files in any medium without
> fee or royalty as long as this notice and license are distributed with them. The originals of these files can be located at:
>
> http://schemas.xmlsoap.org/wsdl/soap12/wsdl11soap12.xsd
>
> THESE SCHEMA FILES ARE PROVIDED "AS IS," AND THE AUTHORS MAKE NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED, REGARDING
> THESE FILES, INCLUDING, BUT NOT LIMITED TO, WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT OR
> TITLE. THE AUTHORS WILL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF OR
> RELATING TO ANY USE OR DISTRIBUTION OF THESE FILES.
>
> The name and trademarks of the Authors may NOT be used in any manner, including advertising or publicity pertaining to these files
> or any program or service that uses these files, written prior permission. Title to copyright in these files will at all times
> remain with the Authors.
>
> No other rights are granted by implication, estoppel or otherwise.
