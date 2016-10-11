#pragma once

#include <turbodbc/description.h>

#include <vector>
#include <memory>
#include <cstring>
#include <boost/variant.hpp>


namespace turbodbc {

struct rows {
    rows(std::size_t rows_to_buffer_);
    std::size_t rows_to_buffer;
};

struct megabytes {
    megabytes(std::size_t megabytes_to_buffer);
    std::size_t megabytes_to_buffer;
};

using buffer_size = boost::variant<rows, megabytes>;

class determine_rows_to_buffer
    : public boost::static_visitor<std::size_t>
{
public:
    determine_rows_to_buffer(std::vector<std::unique_ptr<turbodbc::description const>> const& descriptions);
    std::size_t operator()(rows const& r) const;
    std::size_t operator()(megabytes const& m) const;

private:
    std::vector<std::unique_ptr<description const>> const& descriptions_;
};

class halve_buffer_size
    : public boost::static_visitor<buffer_size>
{
public:
    buffer_size operator()(rows const& r) const;
    buffer_size operator()(megabytes const& m) const;
};

}