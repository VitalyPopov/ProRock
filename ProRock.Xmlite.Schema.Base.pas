unit ProRock.Xmlite.Schema.Base;

(*
    This unit was automatically generated using ProRocket 1.0.2 Lite (ProRock 1.0.1)
    Generated (UTC): 2026-01-07T13:22:43.077Z
    Namespace: http://www.w3.org/2001/XMLSchema
    
    ProRock is a free and open-source Delphi library. Feedback and contributions are welcome.
    https://github.com/VitalyPopov/ProRock
*)


interface

uses
  ProRock.Xmlite, ProRock.Xmlite.Schema.Xml;

type
  TFormChoiceST = (fcQualified, fcUnqualified);
  TReducedDerivationControlST = (rdcExtension, rdcRestriction);
  TTypeDerivationControlST = (tdcExtension, tdcRestriction, tdcList, tdcUnion);
  TDerivationControlST = (dcSubstitution, dcExtension, dcRestriction, dcList, dcUnion);

  TAnySimpleTypeST = type string;
  TBase64BinaryST = type string;
  TBooleanST = type boolean;
  TDecimalST = type extended;
  TDoubleST = type extended;
  TFloatST = type extended;
  THexBinaryST = type string;
  TIntegerST = type int64;
  TStringST = type string;
  TAnyURIST = type TAnySimpleTypeST;
  TBlockSetST = type TAnySimpleTypeST;
  TDateST = type TAnySimpleTypeST;
  TDateTimeST = type TAnySimpleTypeST;
  TDerivationSetST = type TAnySimpleTypeST;
  TDurationST = type TAnySimpleTypeST;
  [TNaming(TNaming.nUpperCase)]
  TEntitiesST = type TAnySimpleTypeST;
  TFullDerivationSetST = type TAnySimpleTypeST;
  TGDayST = type TAnySimpleTypeST;
  TGMonthDayST = type TAnySimpleTypeST;
  TGMonthST = type TAnySimpleTypeST;
  TGYearMonthST = type TAnySimpleTypeST;
  TGYearST = type TAnySimpleTypeST;
  [TNaming(TNaming.nUpperCase)]
  TIdrefsST = type TAnySimpleTypeST;
  TLongST = type TIntegerST;
  TNamespaceListST = type TAnySimpleTypeST;
  [TNaming(TNaming.nUpperCase)]
  TNmtokensST = type TAnySimpleTypeST;
  TNonNegativeIntegerST = type TIntegerST;
  TNonPositiveIntegerST = type TIntegerST;
  TNormalizedStringST = type TStringST;
  [TNaming(TNaming.nUpperCase)]
  TNotationST = type TAnySimpleTypeST;
  [TNaming(TNaming.nPascalCase)]
  TQNameST = type TAnySimpleTypeST;
  TSimpleDerivationSetST = type TAnySimpleTypeST;
  TTimeST = type TAnySimpleTypeST;
  [TValueAlias(High(TNonNegativeIntegerST), 'unbounded')]
  TAllNNIST = type TNonNegativeIntegerST;
  TIntST = type TLongST;
  TNegativeIntegerST = type TNonPositiveIntegerST;
  TPositiveIntegerST = type TNonNegativeIntegerST;
  TTokenST = type TNormalizedStringST;
  TUnsignedLongST = type TNonNegativeIntegerST;
  TLanguageST = type TTokenST;
  [TNaming(TNaming.nPascalCase)]
  TNameST = type TTokenST;
  [TNaming(TNaming.nUpperCase)]
  TNmtokenST = type TTokenST;
  TPublicST = type TTokenST;
  TShortST = type TIntST;
  TUnsignedIntST = type TUnsignedLongST;
  TByteST = type TShortST;
  [TNaming(TNaming.nPascalCase)]
  TNCNameST = type TNameST;
  TUnsignedShortST = type TUnsignedIntST;
  [TNaming(TNaming.nUpperCase)]
  TEntityST = type TNCNameST;
  [TNaming(TNaming.nUpperCase)]
  TIdST = type TNCNameST;
  [TNaming(TNaming.nUpperCase)]
  TIdrefST = type TNCNameST;
  TUnsignedByteST = type TUnsignedShortST;

  TOpenAttrsCT = class;
  TAnnotatedCT = class;
  TAttributeCT = class;
  TTopLevelAttributeCT = class;
  TComplexTypeCT = class;
  TTopLevelComplexTypeCT = class;
  TLocalComplexTypeCT = class;
  TRestrictionTypeCT = class;
  TComplexRestrictionTypeCT = class;
  TExtensionTypeCT = class;
  TSimpleRestrictionTypeCT = class;
  TSimpleExtensionTypeCT = class;
  TElementCT = class;
  TTopLevelElementCT = class;
  TLocalElementCT = class;
  TGroupCT = class;
  TRealGroupCT = class;
  TNamedGroupAllCT = class;
  TNamedGroupCT = class;
  TGroupRefCT = class;
  TExplicitGroupCT = class;
  TSimpleExplicitGroupCT = class;
  TNarrowMaxMinCT = class;
  TAllCT = class;
  TWildcardCT = class;
  TAttributeGroupCT = class;
  TNamedAttributeGroupCT = class;
  TAttributeGroupRefCT = class;
  TKeybaseCT = class;
  TAnyTypeCT = class;
  TSimpleTypeCT = class;
  TTopLevelSimpleTypeCT = class;
  TLocalSimpleTypeCT = class;
  TFacetCT = class;
  TNoFixedFacetCT = class;
  TNumFacetCT = class;
  TOccursAG = class;
  TDefRefAG = class;
  TSchemaE = class;
  TAnyAttributeE = class;
  TComplexContentE = class;
  TSimpleContentE = class;
  TComplexTypeE = class;
  TElementE = class;
  TAllE = class;
  TChoiceE = class;
  TSequenceE = class;
  TGroupE = class;
  TAnyE = class;
  TAttributeE = class;
  TAttributeGroupE = class;
  TIncludeE = class;
  TRedefineE = class;
  TImportE = class;
  TSelectorE = class;
  TFieldE = class;
  TUniqueE = class;
  TKeyE = class;
  TKeyrefE = class;
  TNotationE = class;
  TAppinfoE = class;
  TDocumentationE = class;
  TAnnotationE = class;
  TSimpleTypeE = class;
  TRestrictionE = class;
  TListE = class;
  TUnionE = class;
  TMinExclusiveE = class;
  TMinInclusiveE = class;
  TMaxExclusiveE = class;
  TMaxInclusiveE = class;
  TTotalDigitsE = class;
  TFractionDigitsE = class;
  TLengthE = class;
  TMinLengthE = class;
  TMaxLengthE = class;
  TEnumerationE = class;
  TWhiteSpaceE = class;
  TPatternE = class;
  TSchemaTopEG = class;
  TRedefinableEG = class;
  TTypeDefParticleEG = class;
  TNestedParticleEG = class;
  TParticleEG = class;
  TAttrDeclsEG = class;
  TComplexTypeModelEG = class;
  TAllModelEG = class;
  TIdentityConstraintEG = class;
  TSimpleDerivationEG = class;
  TFacetsEG = class;
  TSimpleRestrictionModelEG = class;

  TOpenAttrsCTList = class;
  TAnnotatedCTList = class;
  TAttributeCTList = class;
  TTopLevelAttributeCTList = class;
  TComplexTypeCTList = class;
  TTopLevelComplexTypeCTList = class;
  TLocalComplexTypeCTList = class;
  TRestrictionTypeCTList = class;
  TComplexRestrictionTypeCTList = class;
  TExtensionTypeCTList = class;
  TSimpleRestrictionTypeCTList = class;
  TSimpleExtensionTypeCTList = class;
  TElementCTList = class;
  TTopLevelElementCTList = class;
  TLocalElementCTList = class;
  TGroupCTList = class;
  TRealGroupCTList = class;
  TNamedGroupAllCTList = class;
  TNamedGroupCTList = class;
  TGroupRefCTList = class;
  TExplicitGroupCTList = class;
  TSimpleExplicitGroupCTList = class;
  TNarrowMaxMinCTList = class;
  TAllCTList = class;
  TWildcardCTList = class;
  TAttributeGroupCTList = class;
  TNamedAttributeGroupCTList = class;
  TAttributeGroupRefCTList = class;
  TKeybaseCTList = class;
  TAnyTypeCTList = class;
  TSimpleTypeCTList = class;
  TTopLevelSimpleTypeCTList = class;
  TLocalSimpleTypeCTList = class;
  TFacetCTList = class;
  TNoFixedFacetCTList = class;
  TNumFacetCTList = class;
  TSchemaEList = class;
  TAnyAttributeEList = class;
  TComplexContentEList = class;
  TSimpleContentEList = class;
  TComplexTypeEList = class;
  TElementEList = class;
  TAllEList = class;
  TChoiceEList = class;
  TSequenceEList = class;
  TGroupEList = class;
  TAnyEList = class;
  TAttributeEList = class;
  TAttributeGroupEList = class;
  TIncludeEList = class;
  TRedefineEList = class;
  TImportEList = class;
  TSelectorEList = class;
  TFieldEList = class;
  TUniqueEList = class;
  TKeyEList = class;
  TKeyrefEList = class;
  TNotationEList = class;
  TAppinfoEList = class;
  TDocumentationEList = class;
  TAnnotationEList = class;
  TSimpleTypeEList = class;
  TRestrictionEList = class;
  TListEList = class;
  TUnionEList = class;
  TMinExclusiveEList = class;
  TMinInclusiveEList = class;
  TMaxExclusiveEList = class;
  TMaxInclusiveEList = class;
  TTotalDigitsEList = class;
  TFractionDigitsEList = class;
  TLengthEList = class;
  TMinLengthEList = class;
  TMaxLengthEList = class;
  TEnumerationEList = class;
  TWhiteSpaceEList = class;
  TPatternEList = class;

  TOpenAttrsCT = class(TXmliteComplexTypeRestricted);

  TAnnotatedCT = class(TOpenAttrsCT)
  private
    fId: TIdST;
    fAnnotation: TAnnotationE;
  published
    property Id: TIdST read fId write fId;
    property Annotation: TAnnotationE read fAnnotation;
  end;

  TAttributeCT = class(TAnnotatedCT)
  type
    TUseST = (uProhibited, uOptional, uRequired);
  private
    fType: TQNameST;
    fUse: TUseST;
    fDefault: TStringST;
    fFixed: TStringST;
    fForm: TFormChoiceST;
    fName: TNCNameST;
    fRef: TQNameST;
    fSimpleType: TLocalSimpleTypeCT;
  published
    property &Type: TQNameST read fType write fType;
    [TDefault(Ord(uOptional))]
    property Use: TUseST read fUse write fUse;
    property Default: TStringST read fDefault write fDefault;
    property Fixed: TStringST read fFixed write fFixed;
    property Form: TFormChoiceST read fForm write fForm;
    property Name: TNCNameST read fName write fName;
    property Ref: TQNameST read fRef write fRef;
    property SimpleType: TLocalSimpleTypeCT read fSimpleType;
  end;

  TTopLevelAttributeCT = class(TXmliteComplexTypeRestricted)
  type
    TUseST = (uaProhibited, uaOptional, uaRequired);
  private
    fId: TIdST;
    fType: TQNameST;
    fDefault: TStringST;
    fFixed: TStringST;
    fName: TNCNameST;
    fAnnotation: TAnnotationE;
    fSimpleType: TLocalSimpleTypeCT;
  published
    property Id: TIdST read fId write fId;
    property &Type: TQNameST read fType write fType;
    property Default: TStringST read fDefault write fDefault;
    property Fixed: TStringST read fFixed write fFixed;
    property Name: TNCNameST read fName write fName;
    property Annotation: TAnnotationE read fAnnotation;
    property SimpleType: TLocalSimpleTypeCT read fSimpleType;
  end;

  TComplexTypeCT = class(TAnnotatedCT)
  private
    fName: TNCNameST;
    fMixed: TBooleanST;
    fAbstract: TBooleanST;
    fFinal: TDerivationSetST;
    fBlock: TDerivationSetST;
    fSimpleContent: TSimpleContentE;
    fComplexContent: TComplexContentE;
    fGroup: TGroupRefCT;
    fAll: TAllE;
    fChoice: TChoiceE;
    fSequence: TSequenceE;
    fAnyAttribute: TAnyAttributeE;
    fAttribute: TAttributeCTList;
    fAttributeGroup: TAttributeGroupRefCTList;
  published
    property Name: TNCNameST read fName write fName;
    [TDefault(False)]
    property Mixed: TBooleanST read fMixed write fMixed;
    [TDefault(False)]
    property Abstract: TBooleanST read fAbstract write fAbstract;
    property Final: TDerivationSetST read fFinal write fFinal;
    property Block: TDerivationSetST read fBlock write fBlock;
    property SimpleContent: TSimpleContentE read fSimpleContent;
    property ComplexContent: TComplexContentE read fComplexContent;
    property Group: TGroupRefCT read fGroup;
    property All: TAllE read fAll;
    property Choice: TChoiceE read fChoice;
    property Sequence: TSequenceE read fSequence;
    property AnyAttribute: TAnyAttributeE read fAnyAttribute;
    property Attribute: TAttributeCTList read fAttribute;
    property AttributeGroup: TAttributeGroupRefCTList read fAttributeGroup;
  end;

  TTopLevelComplexTypeCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fName: TNCNameST;
    fMixed: TBooleanST;
    fAbstract: TBooleanST;
    fFinal: TDerivationSetST;
    fBlock: TDerivationSetST;
    fSimpleContent: TSimpleContentE;
    fComplexContent: TComplexContentE;
    fGroup: TGroupRefCT;
    fAll: TAllE;
    fChoice: TChoiceE;
    fSequence: TSequenceE;
    fAnyAttribute: TAnyAttributeE;
    fAttribute: TAttributeCTList;
    fAttributeGroup: TAttributeGroupRefCTList;
    fAnnotation: TAnnotationE;
  published
    property Id: TIdST read fId write fId;
    property Name: TNCNameST read fName write fName;
    [TDefault(False)]
    property Mixed: TBooleanST read fMixed write fMixed;
    [TDefault(False)]
    property Abstract: TBooleanST read fAbstract write fAbstract;
    property Final: TDerivationSetST read fFinal write fFinal;
    property Block: TDerivationSetST read fBlock write fBlock;
    property SimpleContent: TSimpleContentE read fSimpleContent;
    property ComplexContent: TComplexContentE read fComplexContent;
    property Group: TGroupRefCT read fGroup;
    property All: TAllE read fAll;
    property Choice: TChoiceE read fChoice;
    property Sequence: TSequenceE read fSequence;
    property AnyAttribute: TAnyAttributeE read fAnyAttribute;
    property Attribute: TAttributeCTList read fAttribute;
    property AttributeGroup: TAttributeGroupRefCTList read fAttributeGroup;
    property Annotation: TAnnotationE read fAnnotation;
  end;

  TLocalComplexTypeCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fMixed: TBooleanST;
    fSimpleContent: TSimpleContentE;
    fComplexContent: TComplexContentE;
    fGroup: TGroupRefCT;
    fAll: TAllE;
    fChoice: TChoiceE;
    fSequence: TSequenceE;
    fAnyAttribute: TAnyAttributeE;
    fAttribute: TAttributeCTList;
    fAttributeGroup: TAttributeGroupRefCTList;
    fAnnotation: TAnnotationE;
  published
    property Id: TIdST read fId write fId;
    [TDefault(False)]
    property Mixed: TBooleanST read fMixed write fMixed;
    property SimpleContent: TSimpleContentE read fSimpleContent;
    property ComplexContent: TComplexContentE read fComplexContent;
    property Group: TGroupRefCT read fGroup;
    property All: TAllE read fAll;
    property Choice: TChoiceE read fChoice;
    property Sequence: TSequenceE read fSequence;
    property AnyAttribute: TAnyAttributeE read fAnyAttribute;
    property Attribute: TAttributeCTList read fAttribute;
    property AttributeGroup: TAttributeGroupRefCTList read fAttributeGroup;
    property Annotation: TAnnotationE read fAnnotation;
  end;

  TRestrictionTypeCT = class(TAnnotatedCT)
  private
    fBase: TQNameST;
    fAnyAttribute: TAnyAttributeE;
    fAttribute: TAttributeCTList;
    fAttributeGroup: TAttributeGroupRefCTList;
    fGroup: TGroupRefCT;
    fAll: TAllE;
    fChoice: TChoiceE;
    fSequence: TSequenceE;
    fMinExclusive: TMinExclusiveEList;
    fMinInclusive: TMinInclusiveEList;
    fMaxExclusive: TMaxExclusiveEList;
    fMaxInclusive: TMaxInclusiveEList;
    fTotalDigits: TTotalDigitsEList;
    fFractionDigits: TFractionDigitsEList;
    fLength: TLengthEList;
    fMinLength: TMinLengthEList;
    fMaxLength: TMaxLengthEList;
    fEnumeration: TEnumerationEList;
    fWhiteSpace: TWhiteSpaceEList;
    fPattern: TPatternEList;
    fSimpleType: TLocalSimpleTypeCT;
  published
    property Base: TQNameST read fBase write fBase;
    property AnyAttribute: TAnyAttributeE read fAnyAttribute;
    property Attribute: TAttributeCTList read fAttribute;
    property AttributeGroup: TAttributeGroupRefCTList read fAttributeGroup;
    property Group: TGroupRefCT read fGroup;
    property All: TAllE read fAll;
    property Choice: TChoiceE read fChoice;
    property Sequence: TSequenceE read fSequence;
    property MinExclusive: TMinExclusiveEList read fMinExclusive;
    property MinInclusive: TMinInclusiveEList read fMinInclusive;
    property MaxExclusive: TMaxExclusiveEList read fMaxExclusive;
    property MaxInclusive: TMaxInclusiveEList read fMaxInclusive;
    property TotalDigits: TTotalDigitsEList read fTotalDigits;
    property FractionDigits: TFractionDigitsEList read fFractionDigits;
    property Length: TLengthEList read fLength;
    property MinLength: TMinLengthEList read fMinLength;
    property MaxLength: TMaxLengthEList read fMaxLength;
    property Enumeration: TEnumerationEList read fEnumeration;
    property WhiteSpace: TWhiteSpaceEList read fWhiteSpace;
    property Pattern: TPatternEList read fPattern;
    property SimpleType: TLocalSimpleTypeCT read fSimpleType;
  end;

  TComplexRestrictionTypeCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fBase: TQNameST;
    fAnyAttribute: TAnyAttributeE;
    fAttribute: TAttributeCTList;
    fAttributeGroup: TAttributeGroupRefCTList;
    fAnnotation: TAnnotationE;
    fGroup: TGroupRefCT;
    fAll: TAllE;
    fChoice: TChoiceE;
    fSequence: TSequenceE;
  published
    property Id: TIdST read fId write fId;
    property Base: TQNameST read fBase write fBase;
    property AnyAttribute: TAnyAttributeE read fAnyAttribute;
    property Attribute: TAttributeCTList read fAttribute;
    property AttributeGroup: TAttributeGroupRefCTList read fAttributeGroup;
    property Annotation: TAnnotationE read fAnnotation;
    property Group: TGroupRefCT read fGroup;
    property All: TAllE read fAll;
    property Choice: TChoiceE read fChoice;
    property Sequence: TSequenceE read fSequence;
  end;

  TExtensionTypeCT = class(TAnnotatedCT)
  private
    fBase: TQNameST;
    fGroup: TGroupRefCT;
    fAll: TAllE;
    fChoice: TChoiceE;
    fSequence: TSequenceE;
    fAnyAttribute: TAnyAttributeE;
    fAttribute: TAttributeCTList;
    fAttributeGroup: TAttributeGroupRefCTList;
  published
    property Base: TQNameST read fBase write fBase;
    property Group: TGroupRefCT read fGroup;
    property All: TAllE read fAll;
    property Choice: TChoiceE read fChoice;
    property Sequence: TSequenceE read fSequence;
    property AnyAttribute: TAnyAttributeE read fAnyAttribute;
    property Attribute: TAttributeCTList read fAttribute;
    property AttributeGroup: TAttributeGroupRefCTList read fAttributeGroup;
  end;

  TSimpleRestrictionTypeCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fBase: TQNameST;
    fAnyAttribute: TAnyAttributeE;
    fAttribute: TAttributeCTList;
    fAttributeGroup: TAttributeGroupRefCTList;
    fAnnotation: TAnnotationE;
    fMinExclusive: TMinExclusiveEList;
    fMinInclusive: TMinInclusiveEList;
    fMaxExclusive: TMaxExclusiveEList;
    fMaxInclusive: TMaxInclusiveEList;
    fTotalDigits: TTotalDigitsEList;
    fFractionDigits: TFractionDigitsEList;
    fLength: TLengthEList;
    fMinLength: TMinLengthEList;
    fMaxLength: TMaxLengthEList;
    fEnumeration: TEnumerationEList;
    fWhiteSpace: TWhiteSpaceEList;
    fPattern: TPatternEList;
    fSimpleType: TLocalSimpleTypeCT;
  published
    property Id: TIdST read fId write fId;
    property Base: TQNameST read fBase write fBase;
    property AnyAttribute: TAnyAttributeE read fAnyAttribute;
    property Attribute: TAttributeCTList read fAttribute;
    property AttributeGroup: TAttributeGroupRefCTList read fAttributeGroup;
    property Annotation: TAnnotationE read fAnnotation;
    property MinExclusive: TMinExclusiveEList read fMinExclusive;
    property MinInclusive: TMinInclusiveEList read fMinInclusive;
    property MaxExclusive: TMaxExclusiveEList read fMaxExclusive;
    property MaxInclusive: TMaxInclusiveEList read fMaxInclusive;
    property TotalDigits: TTotalDigitsEList read fTotalDigits;
    property FractionDigits: TFractionDigitsEList read fFractionDigits;
    property Length: TLengthEList read fLength;
    property MinLength: TMinLengthEList read fMinLength;
    property MaxLength: TMaxLengthEList read fMaxLength;
    property Enumeration: TEnumerationEList read fEnumeration;
    property WhiteSpace: TWhiteSpaceEList read fWhiteSpace;
    property Pattern: TPatternEList read fPattern;
    property SimpleType: TLocalSimpleTypeCT read fSimpleType;
  end;

  TSimpleExtensionTypeCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fBase: TQNameST;
    fAnyAttribute: TAnyAttributeE;
    fAttribute: TAttributeCTList;
    fAttributeGroup: TAttributeGroupRefCTList;
    fAnnotation: TAnnotationE;
  published
    property Id: TIdST read fId write fId;
    property Base: TQNameST read fBase write fBase;
    property AnyAttribute: TAnyAttributeE read fAnyAttribute;
    property Attribute: TAttributeCTList read fAttribute;
    property AttributeGroup: TAttributeGroupRefCTList read fAttributeGroup;
    property Annotation: TAnnotationE read fAnnotation;
  end;

  TElementCT = class(TAnnotatedCT)
  private
    fType: TQNameST;
    fSubstitutionGroup: TQNameST;
    fDefault: TStringST;
    fFixed: TStringST;
    fNillable: TBooleanST;
    fAbstract: TBooleanST;
    fFinal: TDerivationSetST;
    fBlock: TBlockSetST;
    fForm: TFormChoiceST;
    fName: TNCNameST;
    fRef: TQNameST;
    fMinOccurs: TNonNegativeIntegerST;
    fMaxOccurs: TAllNNIST;
    fUnique: TUniqueEList;
    fKey: TKeyEList;
    fKeyref: TKeyrefEList;
    fSimpleType: TLocalSimpleTypeCT;
    fComplexType: TLocalComplexTypeCT;
  published
    property &Type: TQNameST read fType write fType;
    property SubstitutionGroup: TQNameST read fSubstitutionGroup write fSubstitutionGroup;
    property Default: TStringST read fDefault write fDefault;
    property Fixed: TStringST read fFixed write fFixed;
    [TDefault(False)]
    property Nillable: TBooleanST read fNillable write fNillable;
    [TDefault(False)]
    property Abstract: TBooleanST read fAbstract write fAbstract;
    property Final: TDerivationSetST read fFinal write fFinal;
    property Block: TBlockSetST read fBlock write fBlock;
    property Form: TFormChoiceST read fForm write fForm;
    property Name: TNCNameST read fName write fName;
    property Ref: TQNameST read fRef write fRef;
    [TDefault(1)]
    property MinOccurs: TNonNegativeIntegerST read fMinOccurs write fMinOccurs;
    [TDefault(1)]
    property MaxOccurs: TAllNNIST read fMaxOccurs write fMaxOccurs;
    property Unique: TUniqueEList read fUnique;
    property Key: TKeyEList read fKey;
    property Keyref: TKeyrefEList read fKeyref;
    property SimpleType: TLocalSimpleTypeCT read fSimpleType;
    property ComplexType: TLocalComplexTypeCT read fComplexType;
  end;

  TTopLevelElementCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fType: TQNameST;
    fSubstitutionGroup: TQNameST;
    fDefault: TStringST;
    fFixed: TStringST;
    fNillable: TBooleanST;
    fAbstract: TBooleanST;
    fFinal: TDerivationSetST;
    fBlock: TBlockSetST;
    fName: TNCNameST;
    fUnique: TUniqueEList;
    fKey: TKeyEList;
    fKeyref: TKeyrefEList;
    fAnnotation: TAnnotationE;
    fSimpleType: TLocalSimpleTypeCT;
    fComplexType: TLocalComplexTypeCT;
  published
    property Id: TIdST read fId write fId;
    property &Type: TQNameST read fType write fType;
    property SubstitutionGroup: TQNameST read fSubstitutionGroup write fSubstitutionGroup;
    property Default: TStringST read fDefault write fDefault;
    property Fixed: TStringST read fFixed write fFixed;
    [TDefault(False)]
    property Nillable: TBooleanST read fNillable write fNillable;
    [TDefault(False)]
    property Abstract: TBooleanST read fAbstract write fAbstract;
    property Final: TDerivationSetST read fFinal write fFinal;
    property Block: TBlockSetST read fBlock write fBlock;
    property Name: TNCNameST read fName write fName;
    property Unique: TUniqueEList read fUnique;
    property Key: TKeyEList read fKey;
    property Keyref: TKeyrefEList read fKeyref;
    property Annotation: TAnnotationE read fAnnotation;
    property SimpleType: TLocalSimpleTypeCT read fSimpleType;
    property ComplexType: TLocalComplexTypeCT read fComplexType;
  end;

  TLocalElementCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fType: TQNameST;
    fDefault: TStringST;
    fFixed: TStringST;
    fNillable: TBooleanST;
    fBlock: TBlockSetST;
    fForm: TFormChoiceST;
    fName: TNCNameST;
    fRef: TQNameST;
    fMinOccurs: TNonNegativeIntegerST;
    fMaxOccurs: TAllNNIST;
    fUnique: TUniqueEList;
    fKey: TKeyEList;
    fKeyref: TKeyrefEList;
    fAnnotation: TAnnotationE;
    fSimpleType: TLocalSimpleTypeCT;
    fComplexType: TLocalComplexTypeCT;
  published
    property Id: TIdST read fId write fId;
    property &Type: TQNameST read fType write fType;
    property Default: TStringST read fDefault write fDefault;
    property Fixed: TStringST read fFixed write fFixed;
    [TDefault(False)]
    property Nillable: TBooleanST read fNillable write fNillable;
    property Block: TBlockSetST read fBlock write fBlock;
    property Form: TFormChoiceST read fForm write fForm;
    property Name: TNCNameST read fName write fName;
    property Ref: TQNameST read fRef write fRef;
    [TDefault(1)]
    property MinOccurs: TNonNegativeIntegerST read fMinOccurs write fMinOccurs;
    [TDefault(1)]
    property MaxOccurs: TAllNNIST read fMaxOccurs write fMaxOccurs;
    property Unique: TUniqueEList read fUnique;
    property Key: TKeyEList read fKey;
    property Keyref: TKeyrefEList read fKeyref;
    property Annotation: TAnnotationE read fAnnotation;
    property SimpleType: TLocalSimpleTypeCT read fSimpleType;
    property ComplexType: TLocalComplexTypeCT read fComplexType;
  end;

  TGroupCT = class(TAnnotatedCT)
  private
    fName: TNCNameST;
    fRef: TQNameST;
    fMinOccurs: TNonNegativeIntegerST;
    fMaxOccurs: TAllNNIST;
    fElement: TLocalElementCTList;
    fGroup: TGroupRefCTList;
    fAll: TAllEList;
    fChoice: TChoiceEList;
    fSequence: TSequenceEList;
    fAny: TAnyEList;
  published
    property Name: TNCNameST read fName write fName;
    property Ref: TQNameST read fRef write fRef;
    [TDefault(1)]
    property MinOccurs: TNonNegativeIntegerST read fMinOccurs write fMinOccurs;
    [TDefault(1)]
    property MaxOccurs: TAllNNIST read fMaxOccurs write fMaxOccurs;
    property Element: TLocalElementCTList read fElement;
    property Group: TGroupRefCTList read fGroup;
    property All: TAllEList read fAll;
    property Choice: TChoiceEList read fChoice;
    property Sequence: TSequenceEList read fSequence;
    property Any: TAnyEList read fAny;
  end;

  TRealGroupCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fName: TNCNameST;
    fRef: TQNameST;
    fMinOccurs: TNonNegativeIntegerST;
    fMaxOccurs: TAllNNIST;
    fAnnotation: TAnnotationE;
    fAll: TAllE;
    fChoice: TChoiceE;
    fSequence: TSequenceE;
  published
    property Id: TIdST read fId write fId;
    property Name: TNCNameST read fName write fName;
    property Ref: TQNameST read fRef write fRef;
    [TDefault(1)]
    property MinOccurs: TNonNegativeIntegerST read fMinOccurs write fMinOccurs;
    [TDefault(1)]
    property MaxOccurs: TAllNNIST read fMaxOccurs write fMaxOccurs;
    property Annotation: TAnnotationE read fAnnotation;
    property All: TAllE read fAll;
    property Choice: TChoiceE read fChoice;
    property Sequence: TSequenceE read fSequence;
  end;

  TNamedGroupAllCT = class(TXmliteComplexTypeRestricted)
  type
    TMinOccursST = (mo0, mo1);
    TMaxOccursST = (moa1);
  private
    fId: TIdST;
    fAnnotation: TAnnotationE;
    fElement: TNarrowMaxMinCTList;
  published
    property Id: TIdST read fId write fId;
    property Annotation: TAnnotationE read fAnnotation;
    property Element: TNarrowMaxMinCTList read fElement;
  end;

  TNamedGroupCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fName: TNCNameST;
    fAnnotation: TAnnotationE;
    fAll: TNamedGroupAllCT;
    fChoice: TSimpleExplicitGroupCT;
    fSequence: TSimpleExplicitGroupCT;
  published
    property Id: TIdST read fId write fId;
    property Name: TNCNameST read fName write fName;
    property Annotation: TAnnotationE read fAnnotation;
    property All: TNamedGroupAllCT read fAll;
    property Choice: TSimpleExplicitGroupCT read fChoice;
    property Sequence: TSimpleExplicitGroupCT read fSequence;
  end;

  TGroupRefCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fRef: TQNameST;
    fMinOccurs: TNonNegativeIntegerST;
    fMaxOccurs: TAllNNIST;
    fAnnotation: TAnnotationE;
  published
    property Id: TIdST read fId write fId;
    property Ref: TQNameST read fRef write fRef;
    [TDefault(1)]
    property MinOccurs: TNonNegativeIntegerST read fMinOccurs write fMinOccurs;
    [TDefault(1)]
    property MaxOccurs: TAllNNIST read fMaxOccurs write fMaxOccurs;
    property Annotation: TAnnotationE read fAnnotation;
  end;

  TExplicitGroupCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fMinOccurs: TNonNegativeIntegerST;
    fMaxOccurs: TAllNNIST;
    fElement: TLocalElementCTList;
    fGroup: TGroupRefCTList;
    fChoice: TChoiceEList;
    fSequence: TSequenceEList;
    fAny: TAnyEList;
    fAnnotation: TAnnotationE;
  published
    property Id: TIdST read fId write fId;
    [TDefault(1)]
    property MinOccurs: TNonNegativeIntegerST read fMinOccurs write fMinOccurs;
    [TDefault(1)]
    property MaxOccurs: TAllNNIST read fMaxOccurs write fMaxOccurs;
    property Element: TLocalElementCTList read fElement;
    property Group: TGroupRefCTList read fGroup;
    property Choice: TChoiceEList read fChoice;
    property Sequence: TSequenceEList read fSequence;
    property Any: TAnyEList read fAny;
    property Annotation: TAnnotationE read fAnnotation;
  end;

  TSimpleExplicitGroupCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fElement: TLocalElementCTList;
    fGroup: TGroupRefCTList;
    fChoice: TChoiceEList;
    fSequence: TSequenceEList;
    fAny: TAnyEList;
    fAnnotation: TAnnotationE;
  published
    property Id: TIdST read fId write fId;
    property Element: TLocalElementCTList read fElement;
    property Group: TGroupRefCTList read fGroup;
    property Choice: TChoiceEList read fChoice;
    property Sequence: TSequenceEList read fSequence;
    property Any: TAnyEList read fAny;
    property Annotation: TAnnotationE read fAnnotation;
  end;

  TNarrowMaxMinCT = class(TXmliteComplexTypeRestricted)
  type
    TMinOccursST = (mob0, mob1);
    TMaxOccursST = (moc0, moc1);
  private
    fId: TIdST;
    fType: TQNameST;
    fDefault: TStringST;
    fFixed: TStringST;
    fNillable: TBooleanST;
    fBlock: TBlockSetST;
    fForm: TFormChoiceST;
    fName: TNCNameST;
    fRef: TQNameST;
    fMinOccurs: TNonNegativeIntegerST;
    fMaxOccurs: TAllNNIST;
    fUnique: TUniqueEList;
    fKey: TKeyEList;
    fKeyref: TKeyrefEList;
    fAnnotation: TAnnotationE;
    fSimpleType: TLocalSimpleTypeCT;
    fComplexType: TLocalComplexTypeCT;
  published
    property Id: TIdST read fId write fId;
    property &Type: TQNameST read fType write fType;
    property Default: TStringST read fDefault write fDefault;
    property Fixed: TStringST read fFixed write fFixed;
    [TDefault(False)]
    property Nillable: TBooleanST read fNillable write fNillable;
    property Block: TBlockSetST read fBlock write fBlock;
    property Form: TFormChoiceST read fForm write fForm;
    property Name: TNCNameST read fName write fName;
    property Ref: TQNameST read fRef write fRef;
    [TDefault(1)]
    property MinOccurs: TNonNegativeIntegerST read fMinOccurs write fMinOccurs;
    [TDefault(1)]
    property MaxOccurs: TAllNNIST read fMaxOccurs write fMaxOccurs;
    property Unique: TUniqueEList read fUnique;
    property Key: TKeyEList read fKey;
    property Keyref: TKeyrefEList read fKeyref;
    property Annotation: TAnnotationE read fAnnotation;
    property SimpleType: TLocalSimpleTypeCT read fSimpleType;
    property ComplexType: TLocalComplexTypeCT read fComplexType;
  end;

  TAllCT = class(TXmliteComplexTypeRestricted)
  type
    TMinOccursST = (mod0, mod1);
    TMaxOccursST = (moe1);
  private
    fId: TIdST;
    fMinOccurs: TNonNegativeIntegerST;
    fMaxOccurs: TAllNNIST;
    fAnnotation: TAnnotationE;
    fElement: TNarrowMaxMinCTList;
  published
    property Id: TIdST read fId write fId;
    [TDefault(1)]
    property MinOccurs: TNonNegativeIntegerST read fMinOccurs write fMinOccurs;
    [TDefault(1)]
    property MaxOccurs: TAllNNIST read fMaxOccurs write fMaxOccurs;
    property Annotation: TAnnotationE read fAnnotation;
    property Element: TNarrowMaxMinCTList read fElement;
  end;

  TWildcardCT = class(TAnnotatedCT)
  type
    TProcessContentsST = (pcSkip, pcLax, pcStrict);
  private
    fNamespace: TNamespaceListST;
    fProcessContents: TProcessContentsST;
  published
    [TDefault('##any')]
    property Namespace: TNamespaceListST read fNamespace write fNamespace;
    [TDefault(Ord(pcStrict))]
    property ProcessContents: TProcessContentsST read fProcessContents write fProcessContents;
  end;

  TAttributeGroupCT = class(TAnnotatedCT)
  private
    fName: TNCNameST;
    fRef: TQNameST;
    fAnyAttribute: TAnyAttributeE;
    fAttribute: TAttributeCTList;
    fAttributeGroup: TAttributeGroupRefCTList;
  published
    property Name: TNCNameST read fName write fName;
    property Ref: TQNameST read fRef write fRef;
    property AnyAttribute: TAnyAttributeE read fAnyAttribute;
    property Attribute: TAttributeCTList read fAttribute;
    property AttributeGroup: TAttributeGroupRefCTList read fAttributeGroup;
  end;

  TNamedAttributeGroupCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fName: TNCNameST;
    fAnyAttribute: TAnyAttributeE;
    fAttribute: TAttributeCTList;
    fAttributeGroup: TAttributeGroupRefCTList;
    fAnnotation: TAnnotationE;
  published
    property Id: TIdST read fId write fId;
    property Name: TNCNameST read fName write fName;
    property AnyAttribute: TAnyAttributeE read fAnyAttribute;
    property Attribute: TAttributeCTList read fAttribute;
    property AttributeGroup: TAttributeGroupRefCTList read fAttributeGroup;
    property Annotation: TAnnotationE read fAnnotation;
  end;

  TAttributeGroupRefCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fRef: TQNameST;
    fAnnotation: TAnnotationE;
  published
    property Id: TIdST read fId write fId;
    property Ref: TQNameST read fRef write fRef;
    property Annotation: TAnnotationE read fAnnotation;
  end;

  TKeybaseCT = class(TAnnotatedCT)
  private
    fName: TNCNameST;
    fSelector: TSelectorE;
    fField: TFieldEList;
  published
    property Name: TNCNameST read fName write fName;
    property Selector: TSelectorE read fSelector;
    property Field: TFieldEList read fField;
  end;

  TAnyTypeCT = class(TXmliteComplexType);

  TSimpleTypeCT = class(TAnnotatedCT)
  private
    fFinal: TSimpleDerivationSetST;
    fName: TNCNameST;
    fRestriction: TRestrictionE;
    fList: TListE;
    fUnion: TUnionE;
  published
    property Final: TSimpleDerivationSetST read fFinal write fFinal;
    property Name: TNCNameST read fName write fName;
    property Restriction: TRestrictionE read fRestriction;
    property List: TListE read fList;
    property Union: TUnionE read fUnion;
  end;

  TTopLevelSimpleTypeCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fFinal: TSimpleDerivationSetST;
    fName: TNCNameST;
    fRestriction: TRestrictionE;
    fList: TListE;
    fUnion: TUnionE;
    fAnnotation: TAnnotationE;
  published
    property Id: TIdST read fId write fId;
    property Final: TSimpleDerivationSetST read fFinal write fFinal;
    property Name: TNCNameST read fName write fName;
    property Restriction: TRestrictionE read fRestriction;
    property List: TListE read fList;
    property Union: TUnionE read fUnion;
    property Annotation: TAnnotationE read fAnnotation;
  end;

  TLocalSimpleTypeCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fRestriction: TRestrictionE;
    fList: TListE;
    fUnion: TUnionE;
    fAnnotation: TAnnotationE;
  published
    property Id: TIdST read fId write fId;
    property Restriction: TRestrictionE read fRestriction;
    property List: TListE read fList;
    property Union: TUnionE read fUnion;
    property Annotation: TAnnotationE read fAnnotation;
  end;

  TFacetCT = class(TAnnotatedCT)
  private
    fValue: TAnySimpleTypeST;
    fFixed: TBooleanST;
  published
    property Value: TAnySimpleTypeST read fValue write fValue;
    [TDefault(False)]
    property Fixed: TBooleanST read fFixed write fFixed;
  end;

  TNoFixedFacetCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fValue: TAnySimpleTypeST;
    fAnnotation: TAnnotationE;
  published
    property Id: TIdST read fId write fId;
    property Value: TAnySimpleTypeST read fValue write fValue;
    property Annotation: TAnnotationE read fAnnotation;
  end;

  TNumFacetCT = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fValue: TAnySimpleTypeST;
    fFixed: TBooleanST;
    fAnnotation: TAnnotationE;
  published
    property Id: TIdST read fId write fId;
    property Value: TAnySimpleTypeST read fValue write fValue;
    [TDefault(False)]
    property Fixed: TBooleanST read fFixed write fFixed;
    property Annotation: TAnnotationE read fAnnotation;
  end;

  TOccursAG = class(TXmliteAttributeGroup)
  private
    fMinOccurs: TNonNegativeIntegerST;
    fMaxOccurs: TAllNNIST;
  published
    [TDefault(1)]
    property MinOccurs: TNonNegativeIntegerST read fMinOccurs write fMinOccurs;
    [TDefault(1)]
    property MaxOccurs: TAllNNIST read fMaxOccurs write fMaxOccurs;
  end;

  TDefRefAG = class(TXmliteAttributeGroup)
  private
    fName: TNCNameST;
    fRef: TQNameST;
  published
    property Name: TNCNameST read fName write fName;
    property Ref: TQNameST read fRef write fRef;
  end;

  TSchemaE = class(TOpenAttrsCT)
  private
    fTargetNamespace: TAnyURIST;
    fVersion: TTokenST;
    fFinalDefault: TFullDerivationSetST;
    fBlockDefault: TBlockSetST;
    fAttributeFormDefault: TFormChoiceST;
    fElementFormDefault: TFormChoiceST;
    fId: TIdST;
    fLang: ProRock.Xmlite.Schema.Xml.TLangA;
    fSimpleType: TSimpleTypeEList;
    fComplexType: TComplexTypeEList;
    fGroup: TGroupEList;
    fAttributeGroup: TAttributeGroupEList;
    fElement: TElementEList;
    fAttribute: TAttributeEList;
    fNotation: TNotationEList;
    fAnnotation: TAnnotationEList;
    fInclude: TIncludeEList;
    fImport: TImportEList;
    fRedefine: TRedefineEList;
  published
    property TargetNamespace: TAnyURIST read fTargetNamespace write fTargetNamespace;
    property Version: TTokenST read fVersion write fVersion;
    property FinalDefault: TFullDerivationSetST read fFinalDefault write fFinalDefault;
    property BlockDefault: TBlockSetST read fBlockDefault write fBlockDefault;
    [TDefault(Ord(fcUnqualified))]
    property AttributeFormDefault: TFormChoiceST read fAttributeFormDefault write fAttributeFormDefault;
    [TDefault(Ord(fcUnqualified))]
    property ElementFormDefault: TFormChoiceST read fElementFormDefault write fElementFormDefault;
    property Id: TIdST read fId write fId;
    property Lang: ProRock.Xmlite.Schema.Xml.TLangA read fLang write fLang;
    property SimpleType: TSimpleTypeEList read fSimpleType;
    property ComplexType: TComplexTypeEList read fComplexType;
    property Group: TGroupEList read fGroup;
    property AttributeGroup: TAttributeGroupEList read fAttributeGroup;
    property Element: TElementEList read fElement;
    property Attribute: TAttributeEList read fAttribute;
    property Notation: TNotationEList read fNotation;
    property Annotation: TAnnotationEList read fAnnotation;
    property Include: TIncludeEList read fInclude;
    property Import: TImportEList read fImport;
    property Redefine: TRedefineEList read fRedefine;
  end;

  TAnyAttributeE = class(TWildcardCT);

  TComplexContentE = class(TAnnotatedCT)
  private
    fMixed: TBooleanST;
    fRestriction: TComplexRestrictionTypeCT;
    fExtension: TExtensionTypeCT;
  published
    property Mixed: TBooleanST read fMixed write fMixed;
    property Restriction: TComplexRestrictionTypeCT read fRestriction;
    property Extension: TExtensionTypeCT read fExtension;
  end;

  TSimpleContentE = class(TAnnotatedCT)
  private
    fRestriction: TSimpleRestrictionTypeCT;
    fExtension: TSimpleExtensionTypeCT;
  published
    property Restriction: TSimpleRestrictionTypeCT read fRestriction;
    property Extension: TSimpleExtensionTypeCT read fExtension;
  end;

  TComplexTypeE = class(TTopLevelComplexTypeCT);

  TElementE = class(TTopLevelElementCT);

  TAllE = class(TAllCT);

  TChoiceE = class(TExplicitGroupCT);

  TSequenceE = class(TExplicitGroupCT);

  TGroupE = class(TNamedGroupCT);

  TAnyE = class(TWildcardCT)
  private
    fMinOccurs: TNonNegativeIntegerST;
    fMaxOccurs: TAllNNIST;
  published
    [TDefault(1)]
    property MinOccurs: TNonNegativeIntegerST read fMinOccurs write fMinOccurs;
    [TDefault(1)]
    property MaxOccurs: TAllNNIST read fMaxOccurs write fMaxOccurs;
  end;

  TAttributeE = class(TTopLevelAttributeCT);

  TAttributeGroupE = class(TNamedAttributeGroupCT);

  TIncludeE = class(TAnnotatedCT)
  private
    fSchemaLocation: TAnyURIST;
  published
    property SchemaLocation: TAnyURIST read fSchemaLocation write fSchemaLocation;
  end;

  TRedefineE = class(TOpenAttrsCT)
  private
    fSchemaLocation: TAnyURIST;
    fId: TIdST;
    fSimpleType: TSimpleTypeEList;
    fComplexType: TComplexTypeEList;
    fGroup: TGroupEList;
    fAttributeGroup: TAttributeGroupEList;
    fAnnotation: TAnnotationEList;
  published
    property SchemaLocation: TAnyURIST read fSchemaLocation write fSchemaLocation;
    property Id: TIdST read fId write fId;
    property SimpleType: TSimpleTypeEList read fSimpleType;
    property ComplexType: TComplexTypeEList read fComplexType;
    property Group: TGroupEList read fGroup;
    property AttributeGroup: TAttributeGroupEList read fAttributeGroup;
    property Annotation: TAnnotationEList read fAnnotation;
  end;

  TImportE = class(TAnnotatedCT)
  private
    fNamespace: TAnyURIST;
    fSchemaLocation: TAnyURIST;
  published
    property Namespace: TAnyURIST read fNamespace write fNamespace;
    property SchemaLocation: TAnyURIST read fSchemaLocation write fSchemaLocation;
  end;

  TSelectorE = class(TAnnotatedCT)
  type
    TXpathST = type TTokenST;
  private
    fXpath: TXpathST;
  published
    property Xpath: TXpathST read fXpath write fXpath;
  end;

  TFieldE = class(TAnnotatedCT)
  type
    TXpathST = type TTokenST;
  private
    fXpath: TXpathST;
  published
    property Xpath: TXpathST read fXpath write fXpath;
  end;

  TUniqueE = class(TKeybaseCT);

  TKeyE = class(TKeybaseCT);

  TKeyrefE = class(TKeybaseCT)
  private
    fRefer: TQNameST;
  published
    property Refer: TQNameST read fRefer write fRefer;
  end;

  TNotationE = class(TAnnotatedCT)
  private
    fName: TNCNameST;
    fPublic: TPublicST;
    fSystem: TAnyURIST;
  published
    property Name: TNCNameST read fName write fName;
    property Public: TPublicST read fPublic write fPublic;
    property System: TAnyURIST read fSystem write fSystem;
  end;

  TAppinfoE = class(TXmliteElement)
  private
    fSource: TAnyURIST;
  published
    property Source: TAnyURIST read fSource write fSource;
  end;

  TDocumentationE = class(TXmliteElement)
  private
    fSource: TAnyURIST;
    fLang: ProRock.Xmlite.Schema.Xml.TLangA;
  published
    property Source: TAnyURIST read fSource write fSource;
    property Lang: ProRock.Xmlite.Schema.Xml.TLangA read fLang write fLang;
  end;

  TAnnotationE = class(TOpenAttrsCT)
  private
    fId: TIdST;
    fAppinfo: TAppinfoEList;
    fDocumentation: TDocumentationEList;
  published
    property Id: TIdST read fId write fId;
    property Appinfo: TAppinfoEList read fAppinfo;
    property Documentation: TDocumentationEList read fDocumentation;
  end;

  TSimpleTypeE = class(TTopLevelSimpleTypeCT);

  TRestrictionE = class(TAnnotatedCT)
  private
    fBase: TQNameST;
    fMinExclusive: TMinExclusiveEList;
    fMinInclusive: TMinInclusiveEList;
    fMaxExclusive: TMaxExclusiveEList;
    fMaxInclusive: TMaxInclusiveEList;
    fTotalDigits: TTotalDigitsEList;
    fFractionDigits: TFractionDigitsEList;
    fLength: TLengthEList;
    fMinLength: TMinLengthEList;
    fMaxLength: TMaxLengthEList;
    fEnumeration: TEnumerationEList;
    fWhiteSpace: TWhiteSpaceEList;
    fPattern: TPatternEList;
    fSimpleType: TLocalSimpleTypeCT;
  published
    property Base: TQNameST read fBase write fBase;
    property MinExclusive: TMinExclusiveEList read fMinExclusive;
    property MinInclusive: TMinInclusiveEList read fMinInclusive;
    property MaxExclusive: TMaxExclusiveEList read fMaxExclusive;
    property MaxInclusive: TMaxInclusiveEList read fMaxInclusive;
    property TotalDigits: TTotalDigitsEList read fTotalDigits;
    property FractionDigits: TFractionDigitsEList read fFractionDigits;
    property Length: TLengthEList read fLength;
    property MinLength: TMinLengthEList read fMinLength;
    property MaxLength: TMaxLengthEList read fMaxLength;
    property Enumeration: TEnumerationEList read fEnumeration;
    property WhiteSpace: TWhiteSpaceEList read fWhiteSpace;
    property Pattern: TPatternEList read fPattern;
    property SimpleType: TLocalSimpleTypeCT read fSimpleType;
  end;

  TListE = class(TAnnotatedCT)
  private
    fItemType: TQNameST;
    fSimpleType: TLocalSimpleTypeCT;
  published
    property ItemType: TQNameST read fItemType write fItemType;
    property SimpleType: TLocalSimpleTypeCT read fSimpleType;
  end;

  TUnionE = class(TAnnotatedCT)
  type
    TMemberTypesST = type TAnySimpleTypeST;
  private
    fMemberTypes: TMemberTypesST;
    fSimpleType: TLocalSimpleTypeCTList;
  published
    property MemberTypes: TMemberTypesST read fMemberTypes write fMemberTypes;
    property SimpleType: TLocalSimpleTypeCTList read fSimpleType;
  end;

  TMinExclusiveE = class(TFacetCT);

  TMinInclusiveE = class(TFacetCT);

  TMaxExclusiveE = class(TFacetCT);

  TMaxInclusiveE = class(TFacetCT);

  TTotalDigitsE = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fValue: TAnySimpleTypeST;
    fFixed: TBooleanST;
    fAnnotation: TAnnotationE;
  published
    property Id: TIdST read fId write fId;
    property Value: TAnySimpleTypeST read fValue write fValue;
    [TDefault(False)]
    property Fixed: TBooleanST read fFixed write fFixed;
    property Annotation: TAnnotationE read fAnnotation;
  end;

  TFractionDigitsE = class(TNumFacetCT);

  TLengthE = class(TNumFacetCT);

  TMinLengthE = class(TNumFacetCT);

  TMaxLengthE = class(TNumFacetCT);

  TEnumerationE = class(TNoFixedFacetCT);

  TWhiteSpaceE = class(TXmliteComplexTypeRestricted)
  type
    TValueST = (vPreserve, vReplace, vCollapse);
  private
    fId: TIdST;
    fValue: TAnySimpleTypeST;
    fFixed: TBooleanST;
    fAnnotation: TAnnotationE;
  published
    property Id: TIdST read fId write fId;
    property Value: TAnySimpleTypeST read fValue write fValue;
    [TDefault(False)]
    property Fixed: TBooleanST read fFixed write fFixed;
    property Annotation: TAnnotationE read fAnnotation;
  end;

  TPatternE = class(TXmliteComplexTypeRestricted)
  private
    fId: TIdST;
    fValue: TAnySimpleTypeST;
    fAnnotation: TAnnotationE;
  published
    property Id: TIdST read fId write fId;
    property Value: TAnySimpleTypeST read fValue write fValue;
    property Annotation: TAnnotationE read fAnnotation;
  end;

  TSchemaTopEG = class(TXmliteElementGroup)
  private
    fElement: TElementE;
    fAttribute: TAttributeE;
    fNotation: TNotationE;
  published
    property Element: TElementE read fElement;
    property Attribute: TAttributeE read fAttribute;
    property Notation: TNotationE read fNotation;
  end;

  TRedefinableEG = class(TXmliteElementGroup)
  private
    fSimpleType: TSimpleTypeE;
    fComplexType: TComplexTypeE;
    fGroup: TGroupE;
    fAttributeGroup: TAttributeGroupE;
  published
    property SimpleType: TSimpleTypeE read fSimpleType;
    property ComplexType: TComplexTypeE read fComplexType;
    property Group: TGroupE read fGroup;
    property AttributeGroup: TAttributeGroupE read fAttributeGroup;
  end;

  TTypeDefParticleEG = class(TXmliteElementGroup)
  private
    fGroup: TGroupRefCT;
    fAll: TAllE;
    fChoice: TChoiceE;
    fSequence: TSequenceE;
  published
    property Group: TGroupRefCT read fGroup;
    property All: TAllE read fAll;
    property Choice: TChoiceE read fChoice;
    property Sequence: TSequenceE read fSequence;
  end;

  TNestedParticleEG = class(TXmliteElementGroup)
  private
    fElement: TLocalElementCT;
    fGroup: TGroupRefCT;
    fChoice: TChoiceE;
    fSequence: TSequenceE;
    fAny: TAnyE;
  published
    property Element: TLocalElementCT read fElement;
    property Group: TGroupRefCT read fGroup;
    property Choice: TChoiceE read fChoice;
    property Sequence: TSequenceE read fSequence;
    property Any: TAnyE read fAny;
  end;

  TParticleEG = class(TXmliteElementGroup)
  private
    fElement: TLocalElementCT;
    fGroup: TGroupRefCT;
    fAll: TAllE;
    fChoice: TChoiceE;
    fSequence: TSequenceE;
    fAny: TAnyE;
  published
    property Element: TLocalElementCT read fElement;
    property Group: TGroupRefCT read fGroup;
    property All: TAllE read fAll;
    property Choice: TChoiceE read fChoice;
    property Sequence: TSequenceE read fSequence;
    property Any: TAnyE read fAny;
  end;

  TAttrDeclsEG = class(TXmliteElementGroup)
  private
    fAnyAttribute: TAnyAttributeE;
  published
    property AnyAttribute: TAnyAttributeE read fAnyAttribute;
  end;

  TComplexTypeModelEG = class(TXmliteElementGroup)
  private
    fSimpleContent: TSimpleContentE;
    fComplexContent: TComplexContentE;
  published
    property SimpleContent: TSimpleContentE read fSimpleContent;
    property ComplexContent: TComplexContentE read fComplexContent;
  end;

  TAllModelEG = class(TXmliteElementGroup)
  private
    fAnnotation: TAnnotationE;
  published
    property Annotation: TAnnotationE read fAnnotation;
  end;

  TIdentityConstraintEG = class(TXmliteElementGroup)
  private
    fUnique: TUniqueE;
    fKey: TKeyE;
    fKeyref: TKeyrefE;
  published
    property Unique: TUniqueE read fUnique;
    property Key: TKeyE read fKey;
    property Keyref: TKeyrefE read fKeyref;
  end;

  TSimpleDerivationEG = class(TXmliteElementGroup)
  private
    fRestriction: TRestrictionE;
    fList: TListE;
    fUnion: TUnionE;
  published
    property Restriction: TRestrictionE read fRestriction;
    property List: TListE read fList;
    property Union: TUnionE read fUnion;
  end;

  TFacetsEG = class(TXmliteElementGroup)
  private
    fMinExclusive: TMinExclusiveE;
    fMinInclusive: TMinInclusiveE;
    fMaxExclusive: TMaxExclusiveE;
    fMaxInclusive: TMaxInclusiveE;
    fTotalDigits: TTotalDigitsE;
    fFractionDigits: TFractionDigitsE;
    fLength: TLengthE;
    fMinLength: TMinLengthE;
    fMaxLength: TMaxLengthE;
    fEnumeration: TEnumerationE;
    fWhiteSpace: TWhiteSpaceE;
    fPattern: TPatternE;
  published
    property MinExclusive: TMinExclusiveE read fMinExclusive;
    property MinInclusive: TMinInclusiveE read fMinInclusive;
    property MaxExclusive: TMaxExclusiveE read fMaxExclusive;
    property MaxInclusive: TMaxInclusiveE read fMaxInclusive;
    property TotalDigits: TTotalDigitsE read fTotalDigits;
    property FractionDigits: TFractionDigitsE read fFractionDigits;
    property Length: TLengthE read fLength;
    property MinLength: TMinLengthE read fMinLength;
    property MaxLength: TMaxLengthE read fMaxLength;
    property Enumeration: TEnumerationE read fEnumeration;
    property WhiteSpace: TWhiteSpaceE read fWhiteSpace;
    property Pattern: TPatternE read fPattern;
  end;

  TSimpleRestrictionModelEG = class(TXmliteElementGroup)
  private
    fSimpleType: TLocalSimpleTypeCT;
  published
    property SimpleType: TLocalSimpleTypeCT read fSimpleType;
  end;

  TOpenAttrsCTList = class(TXmliteList<TOpenAttrsCT>);
  TAnnotatedCTList = class(TXmliteList<TAnnotatedCT>);
  TAttributeCTList = class(TXmliteList<TAttributeCT>);
  TTopLevelAttributeCTList = class(TXmliteList<TTopLevelAttributeCT>);
  TComplexTypeCTList = class(TXmliteList<TComplexTypeCT>);
  TTopLevelComplexTypeCTList = class(TXmliteList<TTopLevelComplexTypeCT>);
  TLocalComplexTypeCTList = class(TXmliteList<TLocalComplexTypeCT>);
  TRestrictionTypeCTList = class(TXmliteList<TRestrictionTypeCT>);
  TComplexRestrictionTypeCTList = class(TXmliteList<TComplexRestrictionTypeCT>);
  TExtensionTypeCTList = class(TXmliteList<TExtensionTypeCT>);
  TSimpleRestrictionTypeCTList = class(TXmliteList<TSimpleRestrictionTypeCT>);
  TSimpleExtensionTypeCTList = class(TXmliteList<TSimpleExtensionTypeCT>);
  TElementCTList = class(TXmliteList<TElementCT>);
  TTopLevelElementCTList = class(TXmliteList<TTopLevelElementCT>);
  TLocalElementCTList = class(TXmliteList<TLocalElementCT>);
  TGroupCTList = class(TXmliteList<TGroupCT>);
  TRealGroupCTList = class(TXmliteList<TRealGroupCT>);
  TNamedGroupAllCTList = class(TXmliteList<TNamedGroupAllCT>);
  TNamedGroupCTList = class(TXmliteList<TNamedGroupCT>);
  TGroupRefCTList = class(TXmliteList<TGroupRefCT>);
  TExplicitGroupCTList = class(TXmliteList<TExplicitGroupCT>);
  TSimpleExplicitGroupCTList = class(TXmliteList<TSimpleExplicitGroupCT>);
  TNarrowMaxMinCTList = class(TXmliteList<TNarrowMaxMinCT>);
  TAllCTList = class(TXmliteList<TAllCT>);
  TWildcardCTList = class(TXmliteList<TWildcardCT>);
  TAttributeGroupCTList = class(TXmliteList<TAttributeGroupCT>);
  TNamedAttributeGroupCTList = class(TXmliteList<TNamedAttributeGroupCT>);
  TAttributeGroupRefCTList = class(TXmliteList<TAttributeGroupRefCT>);
  TKeybaseCTList = class(TXmliteList<TKeybaseCT>);
  TAnyTypeCTList = class(TXmliteList<TAnyTypeCT>);
  TSimpleTypeCTList = class(TXmliteList<TSimpleTypeCT>);
  TTopLevelSimpleTypeCTList = class(TXmliteList<TTopLevelSimpleTypeCT>);
  TLocalSimpleTypeCTList = class(TXmliteList<TLocalSimpleTypeCT>);
  TFacetCTList = class(TXmliteList<TFacetCT>);
  TNoFixedFacetCTList = class(TXmliteList<TNoFixedFacetCT>);
  TNumFacetCTList = class(TXmliteList<TNumFacetCT>);
  TSchemaEList = class(TXmliteList<TSchemaE>);
  TAnyAttributeEList = class(TXmliteList<TAnyAttributeE>);
  TComplexContentEList = class(TXmliteList<TComplexContentE>);
  TSimpleContentEList = class(TXmliteList<TSimpleContentE>);
  TComplexTypeEList = class(TXmliteList<TComplexTypeE>);
  TElementEList = class(TXmliteList<TElementE>);
  TAllEList = class(TXmliteList<TAllE>);
  TChoiceEList = class(TXmliteList<TChoiceE>);
  TSequenceEList = class(TXmliteList<TSequenceE>);
  TGroupEList = class(TXmliteList<TGroupE>);
  TAnyEList = class(TXmliteList<TAnyE>);
  TAttributeEList = class(TXmliteList<TAttributeE>);
  TAttributeGroupEList = class(TXmliteList<TAttributeGroupE>);
  TIncludeEList = class(TXmliteList<TIncludeE>);
  TRedefineEList = class(TXmliteList<TRedefineE>);
  TImportEList = class(TXmliteList<TImportE>);
  TSelectorEList = class(TXmliteList<TSelectorE>);
  TFieldEList = class(TXmliteList<TFieldE>);
  TUniqueEList = class(TXmliteList<TUniqueE>);
  TKeyEList = class(TXmliteList<TKeyE>);
  TKeyrefEList = class(TXmliteList<TKeyrefE>);
  TNotationEList = class(TXmliteList<TNotationE>);
  TAppinfoEList = class(TXmliteList<TAppinfoE>);
  TDocumentationEList = class(TXmliteList<TDocumentationE>);
  TAnnotationEList = class(TXmliteList<TAnnotationE>);
  TSimpleTypeEList = class(TXmliteList<TSimpleTypeE>);
  TRestrictionEList = class(TXmliteList<TRestrictionE>);
  TListEList = class(TXmliteList<TListE>);
  TUnionEList = class(TXmliteList<TUnionE>);
  TMinExclusiveEList = class(TXmliteList<TMinExclusiveE>);
  TMinInclusiveEList = class(TXmliteList<TMinInclusiveE>);
  TMaxExclusiveEList = class(TXmliteList<TMaxExclusiveE>);
  TMaxInclusiveEList = class(TXmliteList<TMaxInclusiveE>);
  TTotalDigitsEList = class(TXmliteList<TTotalDigitsE>);
  TFractionDigitsEList = class(TXmliteList<TFractionDigitsE>);
  TLengthEList = class(TXmliteList<TLengthE>);
  TMinLengthEList = class(TXmliteList<TMinLengthE>);
  TMaxLengthEList = class(TXmliteList<TMaxLengthE>);
  TEnumerationEList = class(TXmliteList<TEnumerationE>);
  TWhiteSpaceEList = class(TXmliteList<TWhiteSpaceE>);
  TPatternEList = class(TXmliteList<TPatternE>);

implementation

initialization

TMetaBankXmlite.RegisterNamespace('http://www.w3.org/2001/XMLSchema', [TypeInfo(TFormChoiceST), TypeInfo(TReducedDerivationControlST),
  TypeInfo(TTypeDerivationControlST), TypeInfo(TDerivationControlST), TypeInfo(TDerivationSetST), TypeInfo(TFullDerivationSetST),
  TypeInfo(TAllNNIST), TypeInfo(TBlockSetST), TypeInfo(TNamespaceListST), TypeInfo(TPublicST), TypeInfo(TStringST), TypeInfo(TBooleanST),
  TypeInfo(TFloatST), TypeInfo(TDoubleST), TypeInfo(TDecimalST), TypeInfo(TDurationST), TypeInfo(TDateTimeST), TypeInfo(TTimeST),
  TypeInfo(TDateST), TypeInfo(TGYearMonthST), TypeInfo(TGYearST), TypeInfo(TGMonthDayST), TypeInfo(TGDayST), TypeInfo(TGMonthST),
  TypeInfo(THexBinaryST), TypeInfo(TBase64BinaryST), TypeInfo(TAnyURIST), TypeInfo(TQNameST), TypeInfo(TNotationST),
  TypeInfo(TNormalizedStringST), TypeInfo(TTokenST), TypeInfo(TLanguageST), TypeInfo(TIdrefsST), TypeInfo(TEntitiesST),
  TypeInfo(TNmtokenST), TypeInfo(TNmtokensST), TypeInfo(TNameST), TypeInfo(TNCNameST), TypeInfo(TIdST), TypeInfo(TIdrefST),
  TypeInfo(TEntityST), TypeInfo(TIntegerST), TypeInfo(TNonPositiveIntegerST), TypeInfo(TNegativeIntegerST), TypeInfo(TLongST),
  TypeInfo(TIntST), TypeInfo(TShortST), TypeInfo(TByteST), TypeInfo(TNonNegativeIntegerST), TypeInfo(TUnsignedLongST),
  TypeInfo(TUnsignedIntST), TypeInfo(TUnsignedShortST), TypeInfo(TUnsignedByteST), TypeInfo(TPositiveIntegerST),
  TypeInfo(TSimpleDerivationSetST), TypeInfo(TAnySimpleTypeST)], [TOpenAttrsCT, TAnnotatedCT, TAttributeCT, TTopLevelAttributeCT,
  TComplexTypeCT, TTopLevelComplexTypeCT, TLocalComplexTypeCT, TRestrictionTypeCT, TComplexRestrictionTypeCT, TExtensionTypeCT,
  TSimpleRestrictionTypeCT, TSimpleExtensionTypeCT, TElementCT, TTopLevelElementCT, TLocalElementCT, TGroupCT, TRealGroupCT,
  TNamedGroupAllCT, TNamedGroupCT, TGroupRefCT, TExplicitGroupCT, TSimpleExplicitGroupCT, TNarrowMaxMinCT, TAllCT, TWildcardCT,
  TAttributeGroupCT, TNamedAttributeGroupCT, TAttributeGroupRefCT, TKeybaseCT, TAnyTypeCT, TSimpleTypeCT, TTopLevelSimpleTypeCT,
  TLocalSimpleTypeCT, TFacetCT, TNoFixedFacetCT, TNumFacetCT], [], [TOccursAG, TDefRefAG], [TSchemaE, TAnyAttributeE, TComplexContentE,
  TSimpleContentE, TComplexTypeE, TElementE, TAllE, TChoiceE, TSequenceE, TGroupE, TAnyE, TAttributeE, TAttributeGroupE, TIncludeE,
  TRedefineE, TImportE, TSelectorE, TFieldE, TUniqueE, TKeyE, TKeyrefE, TNotationE, TAppinfoE, TDocumentationE, TAnnotationE, TSimpleTypeE,
  TRestrictionE, TListE, TUnionE, TMinExclusiveE, TMinInclusiveE, TMaxExclusiveE, TMaxInclusiveE, TTotalDigitsE, TFractionDigitsE, TLengthE,
  TMinLengthE, TMaxLengthE, TEnumerationE, TWhiteSpaceE, TPatternE], [TSchemaTopEG, TRedefinableEG, TTypeDefParticleEG, TNestedParticleEG,
  TParticleEG, TAttrDeclsEG, TComplexTypeModelEG, TAllModelEG, TIdentityConstraintEG, TSimpleDerivationEG, TFacetsEG,
  TSimpleRestrictionModelEG], 'xs');

end.
