###
Handler utils
###

# Input parsing

REGEX_NON_ASCII = /[^\x00-\xFF]/g
REGEX_YES = /(?:yes\b|si\b)/
REGEX_NO = /(?:no\b)/

YES_VALUES = ['yes', 'y', 'si', 'sí']
NO_VALUES = ['no', 'n']

###
Check if a value is a `yes` answer

@param [String] value the input value
@returns [Boolean] whether the value is considered a `yes` answer
###
isYes = (value) ->
  _value = value.trim().replace REGEX_NON_ASCII, ''
  _value = _value.toLowerCase()
  if _value in YES_VALUES
    return true
  return REGEX_YES.test _value

###
Check if a value is a `no` answer

@param [String] value the input value
@returns [Boolean] whether the value is considered a `no` answer
###
isNo = (value) ->
  _value = value.trim().replace REGEX_NON_ASCII, ''
  _value = _value.toLowerCase()
  if _value in NO_VALUES
    return true
  return REGEX_NO.test _value

###
Check if a value is in the yes or no range, shorthand function

@param [String] value the input value
@returns [Boolean] whether the value is considered yes or no
###
isYesNo = (value) ->
  return isYes(value) or isNo(value)

module.exports =

  isYes: isYes
  isNo: isNo
  isYesNo: isYesNo