import SwiftSyntax

func isType(_ typeSyntax: TypeSyntax, named name: String) -> Bool {
    if let identifierType = typeSyntax.as(IdentifierTypeSyntax.self),
       identifierType.name.text == name {
        return true
    } else {
        return false
    }
}

func isTypeScoped(_ typeSyntax: TypeSyntax, named name: String) -> (String?, Bool) {
    if let memberType = typeSyntax.as(MemberTypeSyntax.self),
        memberType.name.text == name {
        let typename = "\(memberType.baseType)"
        return (typename, true)
    } else {
        return (nil, false)
    }
}
    
func isOptionalTypeScoped(_ typeSyntax: TypeSyntax, named name: String) -> (String?, Bool) {
    guard let optionalType = typeSyntax.as(OptionalTypeSyntax.self) else {
        return (nil, false)
    }
    return isTypeScoped(optionalType.wrappedType, named: name)
}

func isOptionalType(_ typeSyntax: TypeSyntax, named name: String) -> Bool {
    guard let optionalType = typeSyntax.as(OptionalTypeSyntax.self) else {
        return false
    }
    return isType(optionalType.wrappedType, named: name)
}

func optionalTypeName(_ typeSyntax: TypeSyntax) -> String? {
    guard let optionalType = typeSyntax.as(OptionalTypeSyntax.self),
          let identifier = optionalType.wrappedType.as(IdentifierTypeSyntax.self) else {
        return nil
    }
    return identifier.name.text
}

func optionalType(of baseType: TypeSyntax) -> TypeSyntax {
    TypeSyntax(OptionalTypeSyntax(wrappedType: baseType))
}

func identifierType(_ name: String) -> TypeSyntax {
    TypeSyntax(IdentifierTypeSyntax(name: TokenSyntax(stringLiteral: name)))
}

func identifierType(_ name: String, withArguments args: String...) -> TypeSyntax {
    let arguments = args.enumerated().map { i, name in
        let isLast = i == (args.count - 1)
        let trailingComma = isLast ? nil : TokenSyntax(TokenKind.comma, presence: .present)
        return GenericArgumentSyntax(
            argument: IdentifierTypeSyntax(name: TokenSyntax(stringLiteral: name)),
            trailingComma: trailingComma
        )
    }
    let argumentsClause = GenericArgumentClauseSyntax(arguments: GenericArgumentListSyntax(arguments))
    return TypeSyntax(IdentifierTypeSyntax(name: TokenSyntax(stringLiteral: name), genericArgumentClause: argumentsClause))
}

func memberType(_ name: String, of baseType: TypeSyntax) -> TypeSyntax {
    TypeSyntax(MemberTypeSyntax(baseType: baseType, name: TokenSyntax(stringLiteral: name)))
}

func extractParameterType(_ identifier: IdentifierTypeSyntax, ifTypeEquals typename: String) -> TypeSyntax? {
    guard let generics = identifier.genericArgumentClause,
          let firstArgument = generics.arguments.first,
          generics.arguments.count == 1,
          identifier.name.text == typename else {
        return nil
    }

    return firstArgument.argument
}
    
func doesType(_ type: TypeSyntax, haveName typename: String, withTypeParameters parameterTypenames: String...) -> Bool {
    guard let identifier = type.as(IdentifierTypeSyntax.self),
          identifier.name.text == typename else {
        return false
    }

    guard let generics = identifier.genericArgumentClause,
          generics.arguments.count == parameterTypenames.count else {
        return false
    }
    
    for (argument, parameterTypename) in zip(generics.arguments, parameterTypenames) {
        guard let argumentIdentifier = argument.argument.as(IdentifierTypeSyntax.self),
              argumentIdentifier.name.text == parameterTypename else {
            return false
        }
    }
    
    return true
}

func doesType(_ type: TypeSyntax, haveName typename: String) -> Bool {
    guard let identifier = type.as(IdentifierTypeSyntax.self),
          identifier.name.text == typename else {
        return false
    }

    return identifier.genericArgumentClause == nil
}
