--!strict

--[[
  This file was created with the help of AI. Since I don't have much knowledge on buffering

  Benchmarking:
    ---- BufferCodec Benchmark ----
      Iterations: 10000
      Total (encode + decode): 0.1237 sec
      Encode only:             0.0709 sec
      Decode only:             0.0517 sec
      Memory delta:            3881.00 KB (~ 3MB)
      Ops/sec:                 80822
    
    ---- NonBuff Lua Benchmark ----
      Iterations: 10000
      Total (copy + copy): 0.0283 sec
      Copy only:           0.0139 sec
      Second copy:         0.0173 sec
      Memory delta:        10944.00 KB (~ 11MB)
      Ops/sec:             353966

  As you can see that just using plain lua with tables can make memory delta use 11MB but with the encoder and decoder it uses 3MB.
  This is important if you send a lot of data or infomation over server to client

]]

local Codec = {}

local buffer_create = buffer.create
local buffer_len = buffer.len
local writeu8 = buffer.writeu8
local writei8 = buffer.writei8
local writeu16 = buffer.writeu16
local writei16 = buffer.writei16
local writeu32 = buffer.writeu32
local writei32 = buffer.writei32
local writef32 = buffer.writef32
local writef64 = buffer.writef64
local writestring = buffer.writestring

local readu8 = buffer.readu8
local readi8 = buffer.readi8
local readu16 = buffer.readu16
local readi16 = buffer.readi16
local readu32 = buffer.readu32
local readi32 = buffer.readi32
local readf32 = buffer.readf32
local readf64 = buffer.readf64
local readstring = buffer.readstring

local DataType = {
	NULL = 0,
	BOOLEAN = 1,
	INT8 = 2,
	UINT8 = 3,
	INT16 = 4,
	UINT16 = 5,
	INT32 = 6,
	UINT32 = 7,
	FLOAT32 = 8,
	FLOAT64 = 9,
	STRING = 10,
	VECTOR3 = 11,
	VECTOR2 = 12,
	COLOR3 = 13,
	ARRAY = 14,
	DICTIONARY = 15,
}

Codec.DataType = DataType

local FIXED_SIZE = {
	[DataType.NULL] = 1,
	[DataType.BOOLEAN] = 2,
	[DataType.INT8] = 2,
	[DataType.UINT8] = 2,
	[DataType.INT16] = 3,
	[DataType.UINT16] = 3,
	[DataType.INT32] = 5,
	[DataType.UINT32] = 5,
	[DataType.FLOAT32] = 5,
	[DataType.FLOAT64] = 9,
	[DataType.VECTOR3] = 13,
	[DataType.VECTOR2] = 9,
	[DataType.COLOR3] = 13,
}

function Codec.inferType(value: any): number
	if value == nil then
		return DataType.NULL
	end
	
	local t = typeof(value)
	if t == "boolean" then
		return DataType.BOOLEAN
	elseif t == "number" then
		return DataType.FLOAT64
	elseif t == "string" then
		return DataType.STRING
	elseif t == "Vector3" then
		return DataType.VECTOR3
	elseif t == "Vector2" then
		return DataType.VECTOR2
	elseif t == "Color3" then
		return DataType.COLOR3
	elseif t == "table" then
		return (#value > 0) and DataType.ARRAY or DataType.DICTIONARY
	end

	return DataType.NULL
end

local function calculateSize(value: any, dataType: number): number
	local fixed = FIXED_SIZE[dataType]
	if fixed then 
		return fixed
	end
	
	if dataType == DataType.STRING then
		local str = tostring(value)
		return 1 + 4 + #str
	elseif dataType == DataType.ARRAY then
		local size = 1 + 4
		for i = 1, #value do
			local v = value[i]
			size += calculateSize(v, Codec.inferType(v))
		end
		
		return size
	elseif dataType == DataType.DICTIONARY then
		local size = 1 + 4
		for k, v in pairs(value) do
			size += calculateSize(tostring(k), DataType.STRING)
			size += calculateSize(v, Codec.inferType(v))
		end
		return size
	end
	
	return 1
end

function Codec.encode(value: any, explicitType: number?): buffer
	local rootType = explicitType or Codec.inferType(value)
	local size = calculateSize(value, rootType)
	local buf = buffer.create(size)
	local offset = 0
	
	local function writeValue(val:any, t: number)
		writeu8(buf, offset, t)
		offset += 1
		
		if t == DataType.NULL then
			return
		elseif t == DataType.BOOLEAN then
			writeu8(buf, offset, val and 1 or 0)
			offset += 1
		elseif t == DataType.INT8 then
			writei8(buf, offset, val)
			offset += 1
		elseif t == DataType.UINT8 then
			writeu8(buf, offset, val)
			offset += 1
		elseif t == DataType.INT16 then
			writei16(buf, offset, val)
			offset += 2
		elseif t == DataType.UINT16 then
			writeu16(buf, offset, val)
			offset += 2
		elseif t == DataType.INT32 then
			writei32(buf, offset, val)
			offset += 4
		elseif t == DataType.UINT32 then
			writeu32(buf, offset, val)
			offset += 4
		elseif t == DataType.FLOAT32 then
			writef32(buf, offset, val)
			offset += 4
		elseif t == DataType.FLOAT64 then
			writef64(buf, offset, val)
			offset += 8
		elseif t == DataType.STRING then
			local str = tostring(val)
			writeu32(buf, offset, #str)
			offset += 4
			writestring(buf, offset, str)
			offset += #str
		elseif t == DataType.VECTOR3 then
			writef32(buf, offset, val.X)
			writef32(buf, offset + 4, val.Y)
			writef32(buf, offset + 8, val.Z)
			offset += 12
		elseif t == DataType.VECTOR2 then
			writef32(buf, offset, val.X)
			writef32(buf, offset + 4, val.Y)
			offset += 8
		elseif t == DataType.COLOR3 then
			writef32(buf, offset, val.R)
			writef32(buf, offset + 4, val.G)
			writef32(buf, offset + 8, val.B)
			offset += 12
		elseif t == DataType.ARRAY then
			writeu32(buf, offset, #val)
			offset += 4
			for i = 1, #val do
				local v = val[i]
				writeValue(v, Codec.inferType(v))
			end
		elseif t == DataType.DICTIONARY then
			local count = 0
			for _ in pairs(val) do count += 1 end
			writeu32(buf, offset, count)
			offset += 4
			for k, v in pairs(val) do
				writeValue(tostring(k), DataType.STRING)
				writeValue(v, Codec.inferType(v))
			end
		end
	end
	
	writeValue(value, rootType)
	return buf
end

function Codec.decode(buf: buffer): any
	local offset = 0
	local len = buffer_len(buf)

	local function readValue(): any
		if offset >= len then
			return nil
		end

		local t = readu8(buf, offset)
		offset += 1

		if t == DataType.NULL then
			return nil
		elseif t == DataType.BOOLEAN then
			local v = readu8(buf, offset) == 1
			offset += 1
			return v
		elseif t == DataType.INT8 then
			local v = readi8(buf, offset)
			offset += 1
			return v
		elseif t == DataType.UINT8 then
			local v = readu8(buf, offset)
			offset += 1
			return v
		elseif t == DataType.INT16 then
			local v = readi16(buf, offset)
			offset += 2
			return v
		elseif t == DataType.UINT16 then
			local v = readu16(buf, offset)
			offset += 2
			return v
		elseif t == DataType.INT32 then
			local v = readi32(buf, offset)
			offset += 4
			return v
		elseif t == DataType.UINT32 then
			local v = readu32(buf, offset)
			offset += 4
			return v
		elseif t == DataType.FLOAT32 then
			local v = readf32(buf, offset)
			offset += 4
			return v
		elseif t == DataType.FLOAT64 then
			local v = readf64(buf, offset)
			offset += 8
			return v
		elseif t == DataType.STRING then
			local l = readu32(buf, offset)
			offset += 4
			local s = readstring(buf, offset, l)
			offset += l
			return s
		elseif t == DataType.VECTOR3 then
			local x = readf32(buf, offset)
			local y = readf32(buf, offset + 4)
			local z = readf32(buf, offset + 8)
			offset += 12
			return Vector3.new(x, y, z)
		elseif t == DataType.VECTOR2 then
			local x = readf32(buf, offset)
			local y = readf32(buf, offset + 4)
			offset += 8
			return Vector2.new(x, y)
		elseif t == DataType.COLOR3 then
			local r = readf32(buf, offset)
			local g = readf32(buf, offset + 4)
			local b = readf32(buf, offset + 8)
			offset += 12
			return Color3.new(r, g, b)
		elseif t == DataType.ARRAY then
			local n = readu32(buf, offset)
			offset += 4
			local arr = table.create(n)
			for i = 1, n do
				arr[i] = readValue()
			end
			return arr
		elseif t == DataType.DICTIONARY then
			local n = readu32(buf, offset)
			offset += 4
			local dict = {}
			for _ = 1, n do
				dict[readValue()] = readValue()
			end
			return dict
		end

		return nil
	end

	return readValue()
end

function Codec.encodeAs(value: any, dataType: number): buffer
	return Codec.encode(value, dataType)
end

return Codec
