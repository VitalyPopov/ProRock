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
- `Samples/ProRock.Soapite.WsSecurity/oasis-200401-wss-wssecurity-secext-1.0.xsd` and `...-utility-1.0.xsd` - the OASIS Web
  Services Security 1.0 schemas, https://docs.oasis-open.org/wss/2004/01/, unmodified, with the units ProRocket generates from
  them (`ProRock.Xmlite.Schema.WsSecurity`, `.WsSecurityUtility`) - [OASIS](#oasis)
- `Samples/ProRock.Xmlite.DocumentProperties` - units ProRocket generates from the OPC schemas of ECMA-376 Part 2, 5th edition
  (December 2021: `opc-coreProperties.xsd`, `opc-relationships.xsd`; `ProRock.Xmlite.Schema.CoreProperties`,
  `.Relationships`), and from three schemas of ECMA-376 Part 4 (Transitional Migration Features:
  `shared-documentPropertiesExtended.xsd`, `shared-documentPropertiesVariantTypes.xsd`, `shared-commonSimpleTypes.xsd`;
  `ProRock.Xmlite.Schema.Ooxml.PropExt`, `.PropVar`, `.SimpleTypes`) - [Ecma International](#ecma-international) - and from
  the Dublin Core schemas of DCMI
  (http://dublincore.org/schemas/xmls/qdc/2003/04/02/ `dc.xsd`, `dcterms.xsd`, `dcmitype.xsd`;
  `ProRock.Xmlite.Schema.Dc.Elements`, `.Terms`, `.Types`) - [DCMI](#dcmi). The schemas themselves are not included

---

## OASIS

The OASIS Web Services Security 1.0 schemas carry this notice (verbatim):

> OASIS takes no position regarding the validity or scope of any intellectual property or other rights that might be claimed to pertain to the implementation or use of the technology described in this document or the extent to which any license under such rights might or might not be available; neither does it represent that it has made any effort to identify any such rights. Information on OASIS's procedures with respect to rights in OASIS specifications can be found at the OASIS website. Copies of claims of rights made available for publication and any assurances of licenses to be made available, or the result of an attempt made to obtain a general license or permission for the use of such proprietary rights by implementors or users of this specification, can be obtained from the OASIS Executive Director.
>
> OASIS invites any interested party to bring to its attention any copyrights, patents or patent applications, or other proprietary rights which may cover technology that may be required to implement this specification. Please address the information to the OASIS Executive Director.
>
> Copyright © OASIS Open 2002-2004. All Rights Reserved.
>
> This document and translations of it may be copied and furnished to others, and derivative works that comment on or otherwise explain it or assist in its implementation may be prepared, copied, published and distributed, in whole or in part, without restriction of any kind, provided that the above copyright notice and this paragraph are included on all such copies and derivative works. However, this document itself does not be modified in any way, such as by removing the copyright notice or references to OASIS, except as needed for the purpose of developing OASIS specifications, in which case the procedures for copyrights defined in the OASIS Intellectual Property Rights document must be followed, or as required to translate it into languages other than English.
>
> The limited permissions granted above are perpetual and will not be revoked by OASIS or its successors or assigns.
>
> This document and the information contained herein is provided on an “AS IS” basis and OASIS DISCLAIMS ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTY THAT THE USE OF THE INFORMATION HEREIN WILL NOT INFRINGE ANY RIGHTS OR ANY IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.

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

---

## Ecma International

ECMA-376 Office Open XML File Formats, Part 2: Open Packaging Conventions, 5th edition (December 2021), and Part 4:
Transitional Migration Features (its XML schemas), © Ecma International,
https://ecma-international.org/publications-and-standards/standards/ecma-376/. The published package of Part 2 (its PDF and
schema files) carries no copyright page. Ecma's text copyright policy
(https://www.ecma-international.org/policies/by-ipr/ecma-text-copyright-policy) gives the default notice of Ecma standards,
reproduced here as it appears in ECMA-376 Part 3, 5th edition (verbatim but the year). The generated units are works of kind
(iv): they implement the functionality of the specification (reading and writing its core properties and relationships,
reading the application's properties).

> COPYRIGHT NOTICE
>
> © Ecma International
>
> This document may be copied, published and distributed to others, and certain derivative works of it may be prepared, copied,
> published, and distributed, in whole or in part, provided that the above copyright notice and this Copyright License and
> Disclaimer are included on all such copies and derivative works. The only derivative works that are permissible under this
> Copyright License and Disclaimer are:
>
> (i) works which incorporate all or portion of this document for the purpose of providing commentary or explanation (such as an
> annotated version of the document),
>
> (ii) works which incorporate all or portion of this document for the purpose of incorporating features that provide
> accessibility,
>
> (iii) translations of this document into languages other than English and into different formats and
>
> (iv) works by making use of this specification in standard conformant products by implementing (e.g. by copy and paste wholly
> or partly) the functionality therein.
>
> However, the content of this document itself may not be modified in any way, including by removing the copyright notice or
> references to Ecma International, except as required to translate it into languages other than English or into a different
> format.
>
> The official version of an Ecma International document is the English language version on the Ecma International website. In
> the event of discrepancies between a translated version and the official version, the official version shall govern.
>
> The limited permissions granted above are perpetual and will not be revoked by Ecma International or its successors or assigns.
>
> This document and the information contained herein is provided on an "AS IS" basis and ECMA INTERNATIONAL DISCLAIMS ALL
> WARRANTIES, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTY THAT THE USE OF THE INFORMATION HEREIN WILL NOT
> INFRINGE ANY OWNERSHIP RIGHTS OR ANY IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.

---

## DCMI

The Dublin Core schemas are licensed under a Creative Commons Attribution 4.0 International License (DCMI schema use notice,
https://www.dublincore.org/about/copyright/). The notice DCMI asks for, in the software and its documentation:

> Portions of this software may use XML schemas Copyright © 2011 DCMI, the Dublin Core™ Metadata Initiative. These are licensed under the Creative Commons 4.0 Attribution license.

DCMI: http://dublincore.org/ - License: https://creativecommons.org/licenses/by/4.0/
