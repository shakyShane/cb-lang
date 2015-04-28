{
  function makeInteger(arr) {
    return parseInt(arr.join(''), 10);
  }
  function withPosition(arr) {
    return arr;
    return arr.concat([['line', line()], ['col', column()]]);
  }
  function logger () {
    console.log(opts);
  }
}

start
  = body

/*-------------------------------------------------------------------------------------------------------------------------------------
   body is defined as anything that matches with the part 0 or more times
---------------------------------------------------------------------------------------------------------------------------------------*/
body
  = p:part* {
    return withPosition(p);
  }

/*-------------------------------------------------------------------------------------------------------------------------------------
   part is defined as anything that matches with raw or comment or section or partial or special or reference or buffer
---------------------------------------------------------------------------------------------------------------------------------------*/
part
  = raw / section / reference / buffer

/*-------------------------------------------------------------------------------------------------------------------------------------
   section is defined as matching with with sec_tag_start followed by 0 or more white spaces plus a closing brace plus body
   plus bodies plus end_tag or sec_tag_start followed by a slash and closing brace
---------------------------------------------------------------------------------------------------------------------------------------*/
section "section"
  = t:sec_tag_start ws* rd b:body e:bodies n:end_tag?
// non-self-closing format
   &{
     if ( !n || (t.identifier.value !== n.value) ) {
        error('Expected end tag for ' + t.identifier.value);
     }
     return true;
   }
   {
    t.bodies = b;
    return withPosition(t)
   }
  // self-closing format
  / t:sec_tag_start ws* "/" rd
  {
    t.push(["bodies"]);
    return withPosition(t)
  }

/*-------------------------------------------------------------------------------------------------------------------------------------
   sec_tag_start is defined as matching an opening brace followed by one of #?^<+@% plus identifier plus context plus param
   followed by 0 or more white spaces
---------------------------------------------------------------------------------------------------------------------------------------*/
sec_tag_start
  = ld t:[#?^<+@%] ws* n:identifier c:context p:params
  //{ return [t, n, c, p] }
  { return {type: t, identifier: n, params: p} }

/*-------------------------------------------------------------------------------------------------------------------------------------
   end_tag is defined as matching an opening brace followed by a slash plus 0 or more white spaces plus identifier followed
   by 0 or more white spaces and ends with closing brace
---------------------------------------------------------------------------------------------------------------------------------------*/
end_tag "end tag"
  = ld "/" ws* n:identifier ws* rd
  { return n }

/*-------------------------------------------------------------------------------------------------------------------------------------
   context is defined as matching a colon followed by an identifier
---------------------------------------------------------------------------------------------------------------------------------------*/
context
  = n:(":" n:identifier {return n})?
  { return n ? ["context", n] : ["context"] }

/*-------------------------------------------------------------------------------------------------------------------------------------
  params is defined as matching white space followed by = and identfier or inline
---------------------------------------------------------------------------------------------------------------------------------------*/
params "params"
  = p:(ws+ k:key "=" v:(number / identifier / inline) {return {key: k, value: v}})*
  { return p }

/*-------------------------------------------------------------------------------------------------------------------------------------
   bodies is defined as matching a opening brace followed by key and closing brace, plus body 0 or more times.
---------------------------------------------------------------------------------------------------------------------------------------*/
bodies "bodies"
  = p:(ld ":" k:key rd v:body {return ["param", ["literal", k], v]})*
  { return ["bodies"].concat(p) }

/*-------------------------------------------------------------------------------------------------------------------------------------
   reference is defined as matching a opening brace followed by an identifier plus one or more filters and a closing brace
---------------------------------------------------------------------------------------------------------------------------------------*/
reference "reference"
  = ld n:identifier m:modifiers* rd
  //{ return withPosition(["reference", n, f]) }
  { return withPosition({type: 'reference', identifier: n, modifiers: m}) }

/*-------------------------------------------------------------------------------------------------------------------------------------
   Modifiers are filters/inline_modifiers that act on a value
---------------------------------------------------------------------------------------------------------------------------------------*/
modifiers
     = m:inline_modifiers { return m }
     / f:filters { return f }

/*-------------------------------------------------------------------------------------------------------------------------------------
   filters is defined as matching a pipe character followed by anything that matches the key
---------------------------------------------------------------------------------------------------------------------------------------*/
filters "filters"
  = f:("|" n:key args:key_sep* {return {type: 'filter', value: n, args: args[0]}})
  { return f }

/*-------------------------------------------------------------------------------------------------------------------------------------
   modifiers are defined as matching a colon character followed by anything that matches the key
---------------------------------------------------------------------------------------------------------------------------------------*/
inline_modifiers "inline_modifiers"
  = m:("|" ns:key ":" method:key args:key_sep* {return {type: 'modifier', namespace: ns, method: method, args: args[0]}})
  { return m }

key_sep
  = "~" v:arg_list {return v}

arg_list
  = b:(!rd !'|' a:single_arg* {return a})* {return b[0]}

single_arg
  = ws* ','? ws* a:(number / identifier / inline) ws* {return a}

/*-------------------------------------------------------------------------------------------------------------------------------------
   identifier is defined as matching a path or key
---------------------------------------------------------------------------------------------------------------------------------------*/
identifier "identifier"
  = p:path
  {
    var arr = {}
    arr.paths = p;
    arr.path = p[1].join('.').replace(/,line,\d+,col,\d+/g,'');
    return {type: 'key', value: arr.path, paths: p};
    return arr;
  }
  / k:key
  {
    var arr = ["key", k];
    arr.text = k;
    return {type: 'key', value: k};
  }

number "number"
  = n:(float / integer) { return {type: 'number', value: n} }

float "float"
  = l:integer "." r:unsigned_integer { return parseFloat(l + "." + r); }

unsigned_integer "unsigned_integer"
  = digits:[0-9]+ { return makeInteger(digits); }

signed_integer "signed_integer"
  = sign:'-' n:unsigned_integer { return n * -1; }

integer "integer"
  = signed_integer / unsigned_integer

/*-------------------------------------------------------------------------------------------------------------------------------------
  path is defined as matching a key plus one or more characters of key preceded by a dot
---------------------------------------------------------------------------------------------------------------------------------------*/
path "path"
  = k:key? d:(array_part / array)+
  {
    d = d[0];
    if (k && d) {
      d.unshift(k);
      return withPosition([false, d])
    }
    return withPosition([true, d])
  }
  / "." d:(array_part / array)*
  {
    if (d.length > 0) {
      return withPosition([true, d[0]])
    }
    return withPosition([true, []])
  }

/*-------------------------------------------------------------------------------------------------------------------------------------
   key is defined as a character matching a to z, upper or lower case, followed by 0 or more alphanumeric characters
---------------------------------------------------------------------------------------------------------------------------------------*/
key "key"
  = h:[a-zA-Z_$] t:[0-9a-zA-Z_$-]*
  { return h + t.join('') }

array "array"
  = i:( lb a:( n:([0-9]+) {return n.join('')} / identifier) rb  {return a; }) nk: array_part? { if(nk) { nk.unshift(i); } else {nk = [i] } return nk; }

array_part "array_part"
  = d:("." k:key {return k})+ a:(array)? { if (a) { return d.concat(a); } else { return d; } }

/*-------------------------------------------------------------------------------------------------------------------------------------
   inline params is defined as matching two double quotes or double quotes plus literal followed by closing double quotes or
   double quotes plus inline_part followed by the closing double quotes
---------------------------------------------------------------------------------------------------------------------------------------*/
inline "inline"
  = '"' '"'                 { return withPosition({type: 'string', value: ''}) }
  / '"' l:literal '"'       { return withPosition({type: 'string', value: l}) }
  / '"' p:inline_part+ '"'  { return withPosition(["body"].concat(p)) }

/*-------------------------------------------------------------------------------------------------------------------------------------
  inline_part is defined as matching a special or reference or literal
---------------------------------------------------------------------------------------------------------------------------------------*/
inline_part
  = reference / l:literal { return ["buffer", l] }

buffer "buffer"
  = e:eol w:ws*
  //{ return withPosition(["format", e, w.join('')]) }
  { return withPosition({type: 'format', eol: e, ws: w.join(''), raw: e + w.join('')})}
  / b:(!tag !eol c:. {return c})+
  { return withPosition({type: 'buffer', value: b.join('')}) }

/*-------------------------------------------------------------------------------------------------------------------------------------
   literal is defined as matching esc or any character except the double quotes and it cannot be a tag
---------------------------------------------------------------------------------------------------------------------------------------*/
literal "literal"
  = b:(!tag c:(esc / [^"]) {return c})+
  { return b.join('') }

esc
  = '\\"' { return '"' }

raw "raw"
    = "{`" rawText:(!"`}" char:. {return char})* "`}"
    { return withPosition({type: 'raw', value: rawText.join('')}) }

/*-------------------------------------------------------------------------------------------------------------------------------------
   tag is defined as matching an opening brace plus any of #?^><+%:@/~% plus 0 or more whitespaces plus any character or characters that
   doesn't match rd or eol plus 0 or more whitespaces plus a closing brace
---------------------------------------------------------------------------------------------------------------------------------------*/
tag
  = ld ws* [#?^><+%:@/~%] ws* (!rd !eol .)+ ws* rd
  / reference

ld
  = "{"

rd
  = "}"

lb
  = "["

rb
  = "]"

eol
  = "\n"        //line feed
  / "\r\n"      //carriage + line feed
  / "\r"        //carriage return
  / "\u2028"    //line separator
  / "\u2029"    //paragraph separator

ws
  = [\t\v\f \u00A0\uFEFF] / eol
