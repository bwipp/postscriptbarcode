/*
 * libpostscriptbarcode C++ interface - example.cpp
 *
 * @file example.cpp
 * @author Copyright (c) 2004-2026 Terry Burton.
 *
 * Permission is hereby granted, free of charge, to any
 * person obtaining a copy of this software and associated
 * documentation files (the "Software"), to deal in the
 * Software without restriction, including without
 * limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software
 * is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice
 * shall be included in all copies or substantial portions
 * of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
 * KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
 * THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 *
 */

#include <algorithm>
#include <cstdlib>
#include <iostream>
#include <optional>
#include <string>

#include <postscriptbarcode.hpp>

static unsigned int count_lines(const std::string &s) {
	return static_cast<unsigned int>(
		std::count(s.begin(), s.end(), '\n'));
}

int main(int argc, char *argv[]) {

	try {

		std::optional<bwipp::BWIPP> bwipp;

		if (argc > 1) {
			bwipp.emplace(bwipp::InitOpts{}.filename(argv[1]));
			std::cout << "Version: " << bwipp->get_version() << "\n";
		} else {
			bwipp::BWIPP bwipp1(bwipp::InitOpts{}.filename(
				"../../../build/monolithic_package/barcode.ps"));
			bwipp.emplace(bwipp::InitOpts{}.filename(
				"../../../build/monolithic/barcode.ps"));

			std::cout << "Packaged version: "
			          << bwipp1.get_version() << "\n";
			std::cout << "Unpackaged version: "
			          << bwipp->get_version() << "\n";

			auto ps = bwipp1.emit_all_resources();
			std::cout << "Packaged lines: "
			          << count_lines(ps) << "\n";
		}

		auto ps = bwipp->emit_all_resources();
		std::cout << "Unpackaged lines: " << count_lines(ps) << "\n";

		ps = bwipp->emit_required_resources("qrcode");
		std::cout << "qrcode resource lines: " << count_lines(ps) << "\n";

		ps = bwipp->emit_exec("qrcode", "Hello World", "eclevel=M");
		std::cout << "emit_exec lines: " << count_lines(ps) << "\n";

		auto encoders = bwipp->list_encoders();
		std::cout << "Encoders: " << encoders.size() << "\n";

		auto families = bwipp->list_families();
		std::cout << "Families: " << families.size() << "\n";
		for (const auto &family : families) {
			auto members = bwipp->list_family_members(family);
			std::cout << "  " << family << ": "
			          << members.size() << " members\n";
		}

		auto props = bwipp->list_properties("qrcode");
		std::cout << "qrcode properties: " << props.size() << "\n";
		for (const auto &prop : props)
			std::cout << "  " << prop << ": "
			          << bwipp->get_property("qrcode", prop) << "\n";

		auto prop_map = bwipp->get_properties("qrcode");
		std::cout << "qrcode property pairs: "
		          << prop_map.size() << "\n";
		for (const auto &[key, val] : prop_map)
			std::cout << "  " << key << ": " << val << "\n";

		std::cout << "Hex string: "
		          << bwipp->emit_pshexstr("Hello") << "\n";

		ps = bwipp->emit_template(
			"%dat %opt %enc /uk.co.terryburton.bwipp findresource exec",
			"qrcode", "Hello World", "eclevel=M");
		std::cout << "Template lines: " << count_lines(ps) << "\n";

	} catch (const std::exception &e) {
		std::cerr << e.what() << "\n";
		return EXIT_FAILURE;
	}

	return EXIT_SUCCESS;
}
