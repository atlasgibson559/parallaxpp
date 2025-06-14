--- UTF8 library
-- Helper functions to use on strings that may contain non-English characters.
-- @module ax.utf8

ax.utf8 = ax.utf8 or {}
ax.utf8.upperToLower = {}
ax.utf8.lowerToUpper = {}

--- Changes any upper-case letters in a string to lower-case letters.
-- @realm shared
-- @param str string The string to convert.
-- @return string Returns a string representing the value of a string converted to lower-case.
function ax.utf8:Lower(str)
    local lowercase = ""
    for i = 1, utf8.len(str) do
        local char = utf8.GetChar(str, i)
        lowercase = lowercase .. (self.upperToLower[char] or char)
    end

    return lowercase
end

--- Changes any lower-case letters in a string to upper-case letters.
-- @realm shared
-- @param str string The string to convert.
-- @return string Returns a string representing the value of a string converted to upper-case.
function ax.utf8:Upper(str)
    local uppercase = ""
    for i = 1, utf8.len(str) do
        local char = utf8.GetChar(str, i)
        uppercase = uppercase .. (self.lowerToUpper[char] or char)
    end

    return uppercase
end

--- Registers upper-case to lower-case and lower-case to upper-case charsets.
-- @realm shared
-- @return boolean Returns true if charsets were successfully added, false otherwise.
function ax.utf8:RegisterUTF8(data)
    if ( !istable(data) ) then
        ax.util:PrintError("Attempted to add a UTF8 charset with invalid data table!")
        return false
    end

    table.Merge(self.upperToLower, data)
    table.Merge(self.lowerToUpper, table.Flip(data))

    return true
end

-- English characters
ax.utf8:RegisterUTF8({
    A = "a",
    B = "b",
    C = "c",
    D = "d",
    E = "e",
    F = "f",
    G = "g",
    H = "h",
    I = "i",
    J = "j",
    K = "k",
    L = "l",
    M = "m",
    N = "n",
    O = "o",
    P = "p",
    Q = "q",
    R = "r",
    S = "s",
    T = "t",
    U = "u",
    V = "v",
    W = "w",
    X = "x",
    Y = "y",
    Z = "z"
})

-- Russian characters
ax.utf8:RegisterUTF8({
    А = "а",
    Б = "б",
    В = "в",
    Г = "г",
    Д = "д",
    Е = "е",
    Ё = "ё",
    Ж = "ж",
    З = "з",
    И = "и",
    Й = "й",
    К = "к",
    Л = "л",
    М = "м",
    Н = "н",
    О = "о",
    П = "п",
    Р = "р",
    С = "с",
    Т = "т",
    У = "у",
    Ф = "ф",
    Х = "х",
    Ц = "ц",
    Ч = "ч",
    Ш = "ш",
    Щ = "щ",
    Ъ = "ъ",
    Ы = "ы",
    Ь = "ь",
    Э = "э",
    Ю = "ю",
    Я = "я"
})

-- German characters
ax.utf8:RegisterUTF8({
    Ä = "ä",
    Ö = "ö",
    Ü = "ü",
    ẞ = "ß"
})