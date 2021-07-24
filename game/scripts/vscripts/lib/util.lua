Util = {}

function Util:DumpTable(o)
    if type(o) == 'table' then
       local s = '{\n'
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. self:DumpTable(v) .. ',\n'
       end
       return s .. '}'
    else
       return(tostring(o))
    end
end

function Util:GetKVLength(o)
   local stop = false
   local i = 0

   while not stop do
      if o[tostring(i)] ~= nil then
         i = i + 1
      else
         stop = true
      end
   end
   return i
end

function Util:IsMainHero(hero)
   if hero:IsHero() and hero:IsRealHero() and not hero:IsClone() and not hero:IsIllusion() and not hero:IsTempestDouble() and not hero:IsPhantom() then
      return true
   else
      return false
   end
end