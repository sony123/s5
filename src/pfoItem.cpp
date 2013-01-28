#include "PfoItem.h"

//PfoItem::PfoItem(const QString &local, const QString &s1, const QString &s2, const QString &s3, const QString &s4, const int &v1, const int &v2, QObject* parent) :
PfoItem::PfoItem(const QString &local,
                     const QString &name,
                     const QString &feedLink,
                     const QString &excerpt,
                     const bool &isYahoo,
                     const int &num,
                     const QString &cost,
                     const QString &gain,
                     const QString &value,
                     QObject* parent) :
    ListItem(parent), m_local(local), m_name(name), m_link(feedLink), m_excerpt(excerpt), m_isYahoo(isYahoo), m_num(num), m_cost(cost), m_gain(gain), m_value(value)
{}

QHash<int, QByteArray> PfoItem::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[LocalRole]   = "local";
    roles[NameRole]    = "name";
    roles[LinkRole]    = "feedLink";
    roles[ExcerptRole] = "excerpt";
    roles[IsYahooRole] = "isYahoo";
    roles[NumRole]     = "num";
    roles[CostRole]    = "cost";
    roles[GainRole]    = "gain";
    roles[ValueRole]   = "value";
    return roles;
}

QVariant PfoItem::data(int role) const
{
    switch(role) {
    case LocalRole:
        return local();
    case NameRole:
        return name();
    case LinkRole:
        return feedLink();
    case ExcerptRole:
        return excerpt();
    case IsYahooRole:
        return isYahoo();
    case NumRole:
        return num();
    case CostRole:
        return cost();
    case GainRole:
        return gain();
    case ValueRole:
        return value();
    default:
        return QVariant();
    }
}
