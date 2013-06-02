/*
 * NSString+EscapeHTMLCharacters
 * Copyright 2010 Harry Jordan.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Authored by @inquisitiveSoft (Harry Jordan)
 * 
 * Heavily inspired by http://google-toolbox-for-mac.googlecode.com/svn/trunk/Foundation/GTMNSString+HTML.m
 * in fact the mapOfHTMLEquivalentsForCharacters table is a directly copy
 */


#import "NSString+EscapeHTMLCharacters.h"


typedef struct {
	char *name;
	unichar character;
} DMCharacterDefinition;


static DMCharacterDefinition mapOfHTMLEquivalentsForCharacters[] = {
	{ "&#9;",		9 },	// Tab character
	
	// Originally from http://www.w3.org/TR/xhtml1/dtds.html#a_dtd_Special_characters
	{ "&quot;",		34 },
	{ "&amp;",		38 },
	{ "&apos;",		39 },
	{ "&lt;",		60 },
	{ "&gt;",		62 },
	{ "&OElig;",	338 },
	{ "&oelig;",	339 },
	{ "&Scaron;",	352 },
	{ "&scaron;",	353 },
	{ "&Yuml;",		376 },
	{ "&circ;",		710 },
	{ "&tilde;",	732 },
	{ "&ensp;",		8194 },
	{ "&emsp;",		8195 },
	{ "&thinsp;",	8201 },
	{ "&zwnj;",		8204 },
	{ "&zwj;",	 	8205 },
	{ "&lrm;",	 	8206 },
	{ "&rlm;",	 	8207 },
	{ "&ndash;", 	8211 },
	{ "&mdash;", 	8212 },
	{ "&lsquo;", 	8216 },
	{ "&rsquo;", 	8217 },
	{ "&sbquo;", 	8218 },
	{ "&ldquo;", 	8220 },
	{ "&rdquo;", 	8221 },
	{ "&bdquo;", 	8222 },
	{ "&dagger;",	8224 },
	{ "&Dagger;",	8225 },
	{ "&permil;",	8240 },
	{ "&lsaquo;",	8249 },
	{ "&rsaquo;",	8250 },
	{ "&euro;",		8364 },
};

static const size_t numberOfHTMLEquivalents = 34;		// ToDo: expand the range of characters


int compareCharacterDefinitions(void const *firstEquivalent, void const *secondEquivalent) {
	const DMCharacterDefinition firstCharacter = *(const DMCharacterDefinition *)firstEquivalent;
	const DMCharacterDefinition secondCharacter = *(const DMCharacterDefinition *)secondEquivalent;
	
	if(firstCharacter.character < secondCharacter.character)
		return -1;
	else if(firstCharacter.character == secondCharacter.character)
		return 0;
	
	return 1;
}



@implementation NSString (DMEscapeHTMLCharacters)


- (NSString *)stringByEscapingHTML
{
	NSInteger length = self.length;
	if(length <= 0)
		return self;
	
	NSMutableString *result = [[NSMutableString alloc] init];
	const char *cString = [self cStringUsingEncoding:NSUTF8StringEncoding];
	
	// Iteration state
	NSInteger characterIndex = 0;
	BOOL previousCharacterIsWhiteSpace = FALSE;
	BOOL previousCharacterIsEscapedWhiteSpace = FALSE;
	
	for(characterIndex = 0; characterIndex < length; characterIndex++) {
		// First, handle spaces as a special case
		if(cString[characterIndex] == ' ') {
			// If there are more than one space characters in a row then add &nbsp;'s
			if(previousCharacterIsWhiteSpace) {
				if(!previousCharacterIsEscapedWhiteSpace) {
					// Replace the previous normal space character
					[result replaceCharactersInRange:NSMakeRange([result length] - 1, 1) withString:@"&nbsp;"];
				}
				
				[result appendString:@"&nbsp;"];
				previousCharacterIsEscapedWhiteSpace = TRUE;
			} else
				[result appendString:@" "];
			
			previousCharacterIsWhiteSpace = TRUE;
		} else {
			// If the character represents a new line then add a <br> tag
			// Doesn't do any clever parsing of paragraphs
			if([[NSCharacterSet newlineCharacterSet] characterIsMember:cString[characterIndex]]) {
				[result appendString:@"<br>\n"];
			} else {
				// If character is not a whitespace or newline character then search
				// mapOfHTMLEquivalentsForCharacters to see if we can find a replacement for it
				DMCharacterDefinition currentCharacter;
				currentCharacter.character = cString[characterIndex];
				DMCharacterDefinition *searchResult = bsearch(&currentCharacter, &mapOfHTMLEquivalentsForCharacters, numberOfHTMLEquivalents, sizeof(DMCharacterDefinition), compareCharacterDefinitions);
				
				if(searchResult != NULL) {
					[result appendFormat:@"%s", searchResult->name];
				} else {
					// Otherwise append the character as is
					[result appendFormat:@"%C", currentCharacter.character];
				}
			}
			
			previousCharacterIsWhiteSpace = FALSE;
			previousCharacterIsEscapedWhiteSpace = FALSE;
		}
	}
	
	
	return [result copy];	// Return an immutable string
}


@end